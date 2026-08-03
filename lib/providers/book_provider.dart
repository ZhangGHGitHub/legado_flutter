import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import '../application/book/batch_book_progress_sync_port.dart';
import '../application/book/chapter_progress_migrator.dart';
import '../application/book/local_book_import_port.dart';
import '../application/book/book_provider_source_port.dart';
import '../application/bookshelf/bookshelf_book_group_controller.dart';
import '../application/bookshelf/bookshelf_book_lifecycle_controller.dart';
import '../domain/repositories/book_repository.dart';
import '../domain/ports/chapter_content_cache_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import '../help/shelf_unread.dart';
import '../model/read_book.dart';
import '../utils/site_busy_guard.dart';

/// 书架批量更新目录的结果，供 UI 展示完整的成功/失败/跳过统计。
class ShelfTocUpdateResult {
  const ShelfTocUpdateResult({
    required this.requested,
    required this.eligible,
    required this.updated,
    required this.failed,
    required this.skipped,
    this.failures = const <String, String>{},
  });

  final int requested;
  final int eligible;
  final int updated;
  final int failed;
  final int skipped;
  final Map<String, String> failures;
}

/// 书籍管理 Provider — 书架、阅读、章节、下载缓存
class BookProvider extends ChangeNotifier {
  BookProvider({
    required BookRepository repository,
    required BookProviderSourcePort sourceService,
    LocalBookImportPort? localBookPort,
    BookshelfBookGroupController? bookshelfGroupController,
    BookshelfBookLifecycleController? bookshelfBookLifecycleController,
    required ChapterContentCachePort contentCache,
  }) : _repository = repository,
       _sourceService = sourceService,
       _localBookPort = localBookPort ?? const UnavailableLocalBookImportPort(),
       _contentCache = contentCache,
       _bookshelfGroupController =
           bookshelfGroupController ??
           BookshelfBookGroupController(repository: repository),
       _bookshelfBookLifecycleController =
           bookshelfBookLifecycleController ??
           BookshelfBookLifecycleController(
             repository: repository,
             contentCache: contentCache,
           ) {
    ReadBook.instance.configure(
      sourceService: _sourceService,
      repository: _repository,
      contentCache: _contentCache,
    );
  }

  final BookRepository _repository;
  final BookProviderSourcePort _sourceService;
  final ChapterContentCachePort _contentCache;
  final LocalBookImportPort _localBookPort;
  final BookshelfBookGroupController _bookshelfGroupController;
  final BookshelfBookLifecycleController _bookshelfBookLifecycleController;

  List<Book> _books = [];
  List<Chapter> _currentChapters = [];
  bool _isLoading = false;
  String? _loadError;

  // 下载状态
  bool _isDownloading = false;
  int _downloadTotal = 0;
  int _downloadCompleted = 0;
  String _downloadBookId = '';
  bool _cancelRequested = false;

  /// 目录加载世代号：取消过期的后台刷新
  int _tocLoadGen = 0;
  bool _isRefreshingToc = false;
  bool get isRefreshingToc => _isRefreshingToc;

  /// 同书并发 loadChapters 合并到一个 Future，避免详情页 + 打开目录双刷
  final Map<String, Future<void>> _inflightTocLoads = {};

  /// 书架下拉刷新：正在联网更新目录的书 ID（对齐 legado `onUpTocBooks`）
  final Set<String> _shelfUpdatingBookIds = {};
  int _shelfUpdateQueued = 0;
  bool _isShelfUpdateRunning = false;
  Future<ShelfTocUpdateResult>? _shelfUpdateFuture;

  /// 本地目录章数 + 当前读到章索引（0-based），供未读角标精确计算
  final Map<String, ({int count, int? durIndex})> _shelfChapterMeta = {};

  bool isBookShelfUpdating(String bookId) =>
      _shelfUpdatingBookIds.contains(bookId);

  bool get isShelfUpdateRunning => _isShelfUpdateRunning;

  /// 待更新 + 更新中数量（对齐 `postUpBooksLiveData` / 主框架角标，后续可接）
  int get shelfUpdateActiveCount =>
      _shelfUpdatingBookIds.length + _shelfUpdateQueued;

  ({int count, int? durIndex})? shelfChapterMeta(String bookId) =>
      _shelfChapterMeta[bookId];

  List<Book> get books => _books;
  List<Chapter> get currentChapters => _currentChapters;
  BookRepository get repository => _repository;
  ChapterContentCachePort get contentCache => _contentCache;
  bool get isLoading => _isLoading;
  String? get loadError => _loadError;
  bool get isDownloading => _isDownloading;
  int get downloadTotal => _downloadTotal;
  int get downloadCompleted => _downloadCompleted;
  String get downloadBookId => _downloadBookId;
  double get downloadProgress =>
      _downloadTotal > 0 ? _downloadCompleted / _downloadTotal : 0.0;

  @visibleForTesting
  static String tocLoadKey({
    required String bookId,
    required String sourceUrl,
  }) => '$bookId\u0000$sourceUrl';

  /// 本地库中该书的章节数（缓存页展示用）
  Future<int> getChapterCount(String bookId) async {
    final list = await _repository.getChapters(bookId);
    return list.length;
  }

  ReadBook get readBook => ReadBook.instance;

  Future<({Book book, ChapterProgress progress})> _migrateReadingProgress(
    Book book, {
    required List<Chapter> oldChapters,
    required List<Chapter> newChapters,
  }) async {
    final shelfBook = findBookById(book.id);
    final base = shelfBook ?? book;
    final progress = ChapterProgressMigrator.migrate(
      oldChapters: oldChapters,
      newChapters: newChapters,
      oldChapterIndex: base.durChapterIndex,
      oldChapterPos: base.currentPageIndex,
    );
    if (newChapters.isEmpty) {
      return (book: base, progress: progress);
    }

    final chapter = newChapters[progress.chapterIndex];
    final next = base.copyWith(
      totalChapterNum: newChapters.length,
      durChapterIndex: progress.chapterIndex,
      currentPageIndex: progress.chapterPos,
      currentChapter: chapter.title,
    );
    if (shelfBook != null &&
        (shelfBook.totalChapterNum != next.totalChapterNum ||
            shelfBook.durChapterIndex != next.durChapterIndex ||
            shelfBook.currentPageIndex != next.currentPageIndex ||
            shelfBook.currentChapter != next.currentChapter)) {
      await _repository.insert(next);
      final shelfIndex = _books.indexWhere((item) => item.id == book.id);
      if (shelfIndex >= 0) _books[shelfIndex] = next;
    }
    return (book: next, progress: progress);
  }

  /// 书架中匹配的书（优先 sourceUrl，其次 书名+作者）
  Book? findShelfBook(Book book) {
    for (final b in _books) {
      if (book.sourceUrl.isNotEmpty &&
          b.sourceUrl.isNotEmpty &&
          b.sourceUrl == book.sourceUrl) {
        return b;
      }
    }
    for (final b in _books) {
      if (b.name == book.name &&
          (book.author.isEmpty || b.author == book.author)) {
        return b;
      }
    }
    return null;
  }

  /// 把当前内存目录落到 [bookId]（加入书架后防止 id 错位丢缓存）
  Future<void> persistCurrentTocFor(Book book) async {
    if (_currentChapters.isEmpty) return;
    final list = _currentChapters.asMap().entries.map((e) {
      final c = e.value;
      return Chapter(
        id: Chapter.idFor(bookId: book.id, url: c.url, index: e.key),
        bookId: book.id,
        title: c.title,
        index: e.key,
        url: c.url,
        isVolume: c.isVolume,
        isVip: c.isVip,
        isPay: c.isPay,
        tag: c.tag,
        baseUrl: c.baseUrl,
        isDownloaded: c.isDownloaded,
        content: c.content,
      );
    }).toList();
    await _repository.insertChapters(list);
    _currentChapters = list;
    final onShelf = findBookById(book.id);
    if (onShelf != null && onShelf.totalChapterNum != list.length) {
      final next = onShelf.copyWith(totalChapterNum: list.length);
      await _repository.insert(next);
      final i = _books.indexWhere((b) => b.id == book.id);
      if (i >= 0) _books[i] = next;
    }
    await _refreshShelfChapterMetaFor(book.id);
    notifyListeners();
  }

  /// 加载书架
  Future<void> loadBooks({bool runMaintenance = true}) async {
    _isLoading = true;
    _loadError = null;
    notifyListeners();
    try {
      _books = await _repository.getAll();
      if (runMaintenance) {
        // 缓存清理和章节元数据只影响维护状态，不能阻塞书架首帧。
        unawaited(runStartupMaintenance());
      }
      _loadError = null;
    } catch (e) {
      _loadError = '加载书架失败: $e';
      debugPrint(_loadError);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 执行书架加载后的启动维护；由启动任务 runner 独立观测和限时。
  Future<void> runStartupMaintenance() async {
    await _contentCache.clearInvalid(_books.map((book) => book.id).toSet());
    await _refreshShelfChapterMetaInBackground();
  }

  /// 从本地导入 TXT/EPUB
  Future<Book?> importLocalBook() async {
    _isLoading = true;
    notifyListeners();
    try {
      final book = await _localBookPort.importFromFile();
      if (book != null) {
        _books = await _repository.getAll();
        await _refreshShelfChapterMetaFor(book.id);
        notifyListeners();
      }
      return book;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 从本地路径导入（WebDAV 远程书籍下载后）
  Future<Book?> importLocalBookFromPath(
    String path, {
    String? displayName,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final book = await _localBookPort.importFromPath(
        path,
        displayName: displayName,
      );
      _books = await _repository.getAll();
      await _refreshShelfChapterMetaFor(book.id);
      notifyListeners();
      return book;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 导入书单条目（仅 name/author/intro）— 对齐 Jingshiro：
  /// 已有同名同作者则跳过，否则对各启用书源做精准搜索后入库。
  Future<({int added, int skipped, int failed})> importBookshelfEntries(
    List<({String name, String author, String intro})> entries, {
    required List<BookSource> sources,
    void Function(int index, int total, String status)? onProgress,
  }) async {
    var added = 0;
    var skipped = 0;
    var failed = 0;
    final enabled = sources.where((s) => s.enabled).toList(growable: false);
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final name = e.name.trim();
      final author = e.author.trim();
      if (name.isEmpty) {
        failed++;
        continue;
      }
      onProgress?.call(i + 1, entries.length, '搜索 $name');
      if (_hasNameAuthor(name, author)) {
        skipped++;
        continue;
      }
      try {
        final hit = await _preciseSearchBook(
          name: name,
          author: author,
          sources: enabled,
        );
        if (hit == null) {
          failed++;
          continue;
        }
        final book = hit.copyWith(
          description: hit.description.isNotEmpty
              ? hit.description
              : e.intro.trim(),
          isFavorite: true,
        );
        await _repository.insert(book);
        added++;
      } catch (err) {
        debugPrint('导入书单失败 $name/$author: $err');
        failed++;
      }
    }
    if (added > 0) {
      _books = await _repository.getAll();
      await _refreshShelfChapterMeta();
      notifyListeners();
    }
    return (added: added, skipped: skipped, failed: failed);
  }

  /// 兼容旧调用：直接插入完整 Book（非 Jingshiro 书单路径）
  Future<int> importBooksFromList(List<Book> incoming) async {
    var added = 0;
    for (final raw in incoming) {
      final exists = _books.any(
        (b) =>
            b.sourceUrl == raw.sourceUrl &&
            b.bookSourceUrl == raw.bookSourceUrl &&
            raw.sourceUrl.isNotEmpty,
      );
      if (exists) continue;
      final idTaken = _books.any((b) => b.id == raw.id);
      final book = idTaken
          ? raw.copyWith(
              id: '${raw.bookSourceUrl}_${raw.sourceUrl.hashCode}_${DateTime.now().microsecondsSinceEpoch}',
            )
          : raw;
      await _repository.insert(book);
      added++;
    }
    if (added > 0) {
      _books = await _repository.getAll();
      await _refreshShelfChapterMeta();
      notifyListeners();
    }
    return added;
  }

  /// 添加网址 — 对齐 Jingshiro [BookshelfViewModel.addBookByUrl] /
  /// [AddToBookshelfDialog]：匹配书源 → getBookInfo → **直接入库**。
  ///
  /// 匹配顺序：
  /// 1. UrlOption 中的 origin
  /// 2. 启用书源中按域名/baseUrl 匹配（getBookSourceAddBook）
  /// 3. 启用书源中 bookUrlPattern 全匹配
  ///
  /// 无匹配书源则跳过该 URL（不回退到「试遍全部书源」）。
  Future<({int success, int fail})> addBooksByUrls(
    String rawText, {
    required List<BookSource> sources,
    void Function(int index, int total, String url)? onProgress,
  }) async {
    final urls = rawText
        .split(RegExp(r'[\r\n]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    var success = 0;
    var fail = 0;
    for (var i = 0; i < urls.length; i++) {
      final line = urls[i];
      onProgress?.call(i + 1, urls.length, line);
      try {
        final ok = await _addOneBookByUrl(line, sources: sources);
        if (ok) {
          success++;
        } else {
          fail++;
        }
      } catch (e) {
        debugPrint('添加网址失败 $line: $e');
        fail++;
      }
    }
    if (success > 0) {
      _books = await _repository.getAll();
      await _refreshShelfChapterMeta();
      notifyListeners();
    }
    return (success: success, fail: fail);
  }

  /// 解析单条网址为 Book（不入库）；供需要预览的场景复用。
  Future<Book> resolveBookFromUrl(
    String bookUrl, {
    required List<BookSource> sources,
  }) async {
    final resolved = await _resolveBookFromUrl(bookUrl, sources: sources);
    if (resolved == null) {
      throw Exception('未找到匹配书源');
    }
    return resolved;
  }

  Future<bool> _addOneBookByUrl(
    String bookUrl, {
    required List<BookSource> sources,
  }) async {
    final pureUrl = _stripUrlOption(bookUrl.trim());
    if (pureUrl.isEmpty) return false;

    // 已按详情页 URL 在书架
    if (_books.any((b) => b.sourceUrl == pureUrl)) return true;

    final book = await _resolveBookFromUrl(bookUrl, sources: sources);
    if (book == null) return false;

    final same = _findByNameAuthor(book.name, book.author);
    if (same != null) {
      // 同名同作者：迁移书源信息（对齐 upToc / migrate）
      final migrated = same.copyWith(
        sourceUrl: book.sourceUrl.isNotEmpty ? book.sourceUrl : same.sourceUrl,
        tocUrl: book.tocUrl.isNotEmpty ? book.tocUrl : same.tocUrl,
        bookSourceUrl: book.bookSourceUrl.isNotEmpty
            ? book.bookSourceUrl
            : same.bookSourceUrl,
        coverUrl: book.coverUrl.isNotEmpty ? book.coverUrl : same.coverUrl,
        description: book.description.isNotEmpty
            ? book.description
            : same.description,
        lastChapter: book.lastChapter ?? same.lastChapter,
        type: 'online',
      );
      await _repository.insert(migrated);
      return true;
    }

    await _repository.insert(book.copyWith(isFavorite: true));
    return true;
  }

  Future<Book?> _resolveBookFromUrl(
    String bookUrl, {
    required List<BookSource> sources,
  }) async {
    final enabled = sources.where((s) => s.enabled).toList(growable: false);
    final pureUrl = _stripUrlOption(bookUrl.trim());
    if (pureUrl.isEmpty) return null;

    final candidates = <BookSource>[];
    final seen = <String>{};

    void addCandidate(BookSource? s) {
      if (s == null) return;
      if (!seen.add(s.bookSourceUrl)) return;
      candidates.add(s);
    }

    // 1) UrlOption.origin
    final originOpt = _parseUrlOptionOrigin(bookUrl);
    if (originOpt != null && originOpt.isNotEmpty) {
      BookSource? byOrigin;
      for (final s in enabled) {
        if (s.bookSourceUrl == originOpt) {
          byOrigin = s;
          break;
        }
      }
      addCandidate(byOrigin);
    }

    // 2) getBookSourceAddBook(baseUrl / host)
    addCandidate(_getBookSourceAddBook(pureUrl, enabled));

    // 3) bookUrlPattern 全匹配（仅有正则的源）
    for (final s in enabled) {
      if (_bookUrlPatternMatches(s, pureUrl)) addCandidate(s);
    }

    if (candidates.isEmpty) return null;

    Object? lastError;
    for (final source in candidates) {
      try {
        final info = await _sourceService.getBookInfo(source, pureUrl);
        final name = (info['name'] ?? info['bookName'] ?? '').trim();
        if (name.isEmpty) {
          lastError = Exception('书源「${source.bookSourceName}」未解析到书名');
          continue;
        }
        final cover = _usableCoverUrl(info['coverUrl']) ?? '';
        final intro = (info['intro'] ?? info['description'] ?? '').trim();
        final last = (info['lastChapter'] ?? '').trim();
        final tocUrl = (info['tocUrl'] ?? '').trim();
        return Book(
          id: '${source.bookSourceUrl}_${pureUrl.hashCode}',
          name: name,
          author: (info['author'] ?? '').trim().isEmpty
              ? '未知作者'
              : info['author']!.trim(),
          coverUrl: cover,
          type: 'online',
          sourceUrl: pureUrl,
          tocUrl: tocUrl,
          description: intro,
          lastChapter: last.isEmpty ? null : last,
          bookSourceUrl: source.bookSourceUrl,
          isFavorite: true,
        );
      } catch (e) {
        lastError = e;
        debugPrint('添加网址尝试 ${source.bookSourceName}: $e');
      }
    }
    if (lastError != null) {
      debugPrint('添加网址全部失败: $lastError');
    }
    return null;
  }

  Future<Book?> _preciseSearchBook({
    required String name,
    required String author,
    required List<BookSource> sources,
  }) async {
    final nameLower = name.toLowerCase();
    final authorLower = author.toLowerCase();
    for (final source in sources) {
      try {
        final results = await _sourceService
            .search(source, name)
            .timeout(const Duration(seconds: 20), onTimeout: () => []);
        if (results.isEmpty) continue;
        final books = _sourceService.resultsToBooks(
          results,
          source.bookSourceUrl,
        );
        for (final b in books) {
          final nOk = b.name.trim().toLowerCase() == nameLower;
          final aOk =
              authorLower.isEmpty ||
              b.author.trim().toLowerCase() == authorLower;
          if (nOk && aOk) {
            return b.copyWith(
              author: b.author.trim().isEmpty ? '未知作者' : b.author.trim(),
              isFavorite: true,
            );
          }
        }
      } catch (e) {
        debugPrint('精准搜索 ${source.bookSourceName}: $e');
      }
    }
    return null;
  }

  bool _hasNameAuthor(String name, String author) =>
      _findByNameAuthor(name, author) != null;

  Book? _findByNameAuthor(String name, String author) {
    final n = name.trim();
    final a = author.trim();
    for (final b in _books) {
      if (b.name.trim() != n) continue;
      if (a.isEmpty || b.author.trim() == a) return b;
    }
    return null;
  }

  /// 对齐 getBookSourceAddBook：按详情页 host 与书源 URL host 匹配
  static BookSource? _getBookSourceAddBook(
    String bookUrl,
    List<BookSource> enabled,
  ) {
    final host = Uri.tryParse(bookUrl)?.host.toLowerCase() ?? '';
    if (host.isEmpty) return null;
    for (final s in enabled) {
      final origin = Uri.tryParse(s.bookSourceUrl)?.host.toLowerCase() ?? '';
      if (origin.isEmpty) continue;
      if (host == origin ||
          host.endsWith('.$origin') ||
          origin.endsWith('.$host') ||
          host.contains(origin) ||
          origin.contains(host)) {
        return s;
      }
    }
    return null;
  }

  static bool _bookUrlPatternMatches(BookSource source, String bookUrl) {
    final pattern = _bookUrlPatternOf(source);
    if (pattern.isEmpty) return false;
    try {
      final m = RegExp(pattern).firstMatch(bookUrl);
      return m != null && m.start == 0 && m.end == bookUrl.length;
    } catch (_) {
      return false;
    }
  }

  static String _bookUrlPatternOf(BookSource source) {
    final direct = source.ruleBookUrlPattern.trim();
    if (direct.isNotEmpty) return direct;
    final raw = source.rawSourceJson;
    if (raw.isEmpty) return '';
    try {
      final obj = raw.startsWith('{')
          ? (jsonDecode(raw) as Map<String, dynamic>?)
          : null;
      final p = obj?['bookUrlPattern'];
      if (p is String) return p.trim();
    } catch (_) {}
    return '';
  }

  /// `https://site/book,{"origin":"https://source"}`
  static String? _parseUrlOptionOrigin(String bookUrl) {
    final i = bookUrl.indexOf(',{');
    if (i < 0) return null;
    try {
      final obj = jsonDecode(bookUrl.substring(i + 1));
      if (obj is Map && obj['origin'] != null) {
        return obj['origin'].toString();
      }
    } catch (_) {}
    return null;
  }

  static String _stripUrlOption(String bookUrl) {
    final i = bookUrl.indexOf(',{');
    return i < 0 ? bookUrl : bookUrl.substring(0, i).trim();
  }

  /// 书架下拉刷新 — 对齐 legado `MainViewModel.upToc` + `BooksFragment` listener：
  /// 非本地书后台并行拉目录，不阻塞下拉指示器；单书更新时列表项显示 `RotateLoading`。
  Future<ShelfTocUpdateResult> refreshShelfToc(
    Iterable<Book> books, {
    required BookSource? Function(Book book) resolveSource,
    bool onlyUpdateRead = false,
    int concurrency = 3,
  }) async {
    final existing = _shelfUpdateFuture;
    if (existing != null) return existing;

    _isShelfUpdateRunning = true;
    notifyListeners();
    late final Future<ShelfTocUpdateResult> current;
    current = _refreshShelfTocBatch(
      books,
      resolveSource: resolveSource,
      onlyUpdateRead: onlyUpdateRead,
      concurrency: concurrency,
    );
    _shelfUpdateFuture = current;
    try {
      return await current;
    } finally {
      if (identical(_shelfUpdateFuture, current)) {
        _shelfUpdateFuture = null;
        _isShelfUpdateRunning = false;
        _shelfUpdateQueued = 0;
        _shelfUpdatingBookIds.clear();
        notifyListeners();
      }
    }
  }

  Future<ShelfTocUpdateResult> _refreshShelfTocBatch(
    Iterable<Book> books, {
    required BookSource? Function(Book book) resolveSource,
    required bool onlyUpdateRead,
    required int concurrency,
  }) async {
    final requestedBooks = <String, Book>{};
    for (final book in books) {
      requestedBooks.putIfAbsent(book.id, () => book);
    }
    final targets = <Book>[];
    for (final book in requestedBooks.values) {
      if (book.type == 'local' || book.bookSourceUrl.isEmpty) continue;
      if (resolveSource(book) == null) continue;
      if (onlyUpdateRead && _hasUnreadChapters(book)) continue;
      if (_shelfUpdatingBookIds.contains(book.id)) continue;
      targets.add(book);
    }
    if (targets.isEmpty) {
      return ShelfTocUpdateResult(
        requested: requestedBooks.length,
        eligible: 0,
        updated: 0,
        failed: 0,
        skipped: requestedBooks.length,
      );
    }

    _shelfUpdateQueued = targets.length;
    notifyListeners();

    var index = 0;
    var updated = 0;
    var failed = 0;
    final failures = <String, String>{};
    Future<void> worker() async {
      while (true) {
        if (index >= targets.length) return;
        final book = targets[index++];
        final source = resolveSource(book);
        if (source == null) {
          _shelfUpdateQueued = (_shelfUpdateQueued - 1).clamp(0, 1 << 30);
          notifyListeners();
          continue;
        }

        _shelfUpdatingBookIds.add(book.id);
        _shelfUpdateQueued = (_shelfUpdateQueued - 1).clamp(0, 1 << 30);
        notifyListeners();
        try {
          await _refreshBookTocOnShelf(book, source);
          _books = await _repository.getAll();
          updated++;
        } catch (e, st) {
          failed++;
          failures[book.id] = e.toString();
          debugPrint('书架目录更新失败 ${book.name}: $e\n$st');
        } finally {
          _shelfUpdatingBookIds.remove(book.id);
          try {
            await _refreshShelfChapterMetaFor(book.id);
          } catch (e, st) {
            debugPrint('书架目录元数据刷新失败 ${book.name}: $e\n$st');
          }
          notifyListeners();
        }
      }
    }

    final workers = List.generate(
      concurrency.clamp(1, targets.length),
      (_) => worker(),
    );
    await Future.wait(workers);
    _shelfUpdateQueued = 0;
    _books = await _repository.getAll();
    await _refreshShelfChapterMeta();
    notifyListeners();
    return ShelfTocUpdateResult(
      requested: requestedBooks.length,
      eligible: targets.length,
      updated: updated,
      failed: failed,
      skipped: requestedBooks.length - targets.length,
      failures: Map.unmodifiable(failures),
    );
  }

  Future<void> _refreshShelfChapterMeta() async {
    _shelfChapterMeta.clear();
    for (final book in _books) {
      await _refreshShelfChapterMetaFor(book.id);
    }
  }

  Future<void> _refreshShelfChapterMetaInBackground() async {
    try {
      await _refreshShelfChapterMeta();
    } catch (error, stackTrace) {
      debugPrint('书架章节元数据后台加载失败: $error\n$stackTrace');
    } finally {
      notifyListeners();
    }
  }

  Future<void> _refreshShelfChapterMetaFor(String bookId) async {
    Book? book;
    for (final b in _books) {
      if (b.id == bookId) {
        book = b;
        break;
      }
    }
    if (book == null) {
      _shelfChapterMeta.remove(bookId);
      return;
    }
    final chapters = await _repository.getChapters(bookId);
    if (chapters.isEmpty) {
      _shelfChapterMeta.remove(bookId);
      return;
    }
    int? durIdx;
    final cur = book.currentChapter;
    if (cur != null && cur.isNotEmpty) {
      durIdx = chapters.indexWhere((c) => c.title == cur);
      if (durIdx < 0) durIdx = null;
    }
    final total = chapters.length;
    final metaDur = durIdx ?? book.durChapterIndex;
    _shelfChapterMeta[bookId] = (count: total, durIndex: metaDur);

    // 升级/TOC 后回填持久化字段，重启后仍可精确算未读
    var next = book;
    var dirty = false;
    if (book.totalChapterNum != total) {
      next = next.copyWith(totalChapterNum: total);
      dirty = true;
    }
    if (durIdx != null && book.durChapterIndex != durIdx) {
      next = next.copyWith(durChapterIndex: durIdx);
      dirty = true;
    }
    if (dirty) {
      await _repository.insert(next);
      final i = _books.indexWhere((b) => b.id == bookId);
      if (i >= 0) _books[i] = next;
    }
  }

  bool _hasUnreadChapters(Book book) {
    final meta = _shelfChapterMeta[book.id];
    return ShelfUnread.evaluate(
      book: book,
      totalChapters: meta?.count,
      durChapterIndex: meta?.durIndex,
    ).visible;
  }

  Future<void> _refreshBookTocOnShelf(Book book, BookSource source) async {
    final remote = await _sourceService.getChapters(book, source: source);
    final local = await _repository.getChapters(book.id);
    final merged = _mergeTocWithLocal(
      remote,
      local,
      reverseToc: book.readConfig.reverseToc,
    );
    await _repository.insertChapters(
      merged
          .map(
            (c) => Chapter(
              id: c.id,
              bookId: c.bookId,
              title: c.title,
              index: c.index,
              url: c.url,
              isVolume: c.isVolume,
              isVip: c.isVip,
              isPay: c.isPay,
              tag: c.tag,
              baseUrl: c.baseUrl,
              isDownloaded: c.isDownloaded,
              content: c.content,
            ),
          )
          .toList(),
    );

    var updated = book;
    try {
      final info = await _sourceService.getBookInfo(source, book.sourceUrl);
      final lastFromInfo = info['lastChapter'];
      final lastFromToc = merged.isNotEmpty ? merged.last.title : null;
      updated = book.copyWith(
        lastChapter: (lastFromInfo != null && lastFromInfo.isNotEmpty)
            ? lastFromInfo
            : lastFromToc,
        totalChapterNum: merged.length,
        coverUrl: info['coverUrl']?.isNotEmpty == true
            ? info['coverUrl']!
            : book.coverUrl,
        description: info['intro']?.isNotEmpty == true
            ? info['intro']!
            : book.description,
      );
    } catch (_) {
      if (merged.isNotEmpty) {
        updated = book.copyWith(
          lastChapter: merged.last.title,
          totalChapterNum: merged.length,
        );
      }
    }
    await _repository.insert(updated);
  }

  /// 仅接受可网络加载的封面，避免相对/空 URL 被 resolve 成站点根路径后覆盖好封面。
  static String? _usableCoverUrl(String? url) {
    final u = url?.trim() ?? '';
    if (u.isEmpty) return null;
    final lower = u.toLowerCase();
    if (!lower.startsWith('http://') && !lower.startsWith('https://')) {
      return null;
    }
    // 站点根路径等不是图片
    final uri = Uri.tryParse(u);
    if (uri == null || uri.host.isEmpty) return null;
    final path = uri.path;
    if (path.isEmpty || path == '/') return null;
    return u;
  }

  /// 换源：保留书架书 id/进度，更新 bookSourceUrl + sourceUrl；已在书架则落库。
  /// [source] 可选；传入时会拉详情页封面/简介，避免搜索结果封面为空或无效。
  Future<Book> changeSource(
    Book current,
    Book selected, {
    BookSource? source,
  }) async {
    final shelf = findBookById(current.id) ?? findShelfBook(current);
    final base = shelf ?? current;
    final last = selected.lastChapter?.trim().isNotEmpty == true
        ? selected.lastChapter
        : (selected.description.trim().isNotEmpty
              ? selected.description
              : base.lastChapter);
    var updated = base.copyWith(
      sourceUrl: selected.sourceUrl,
      bookSourceUrl: selected.bookSourceUrl,
      coverUrl: _usableCoverUrl(selected.coverUrl) ?? base.coverUrl,
      lastChapter: last,
      author: selected.author.isNotEmpty ? selected.author : base.author,
      description: selected.description.isNotEmpty
          ? selected.description
          : base.description,
    );

    if (source != null && updated.sourceUrl.isNotEmpty) {
      try {
        final info = await _sourceService.getBookInfo(
          source,
          updated.sourceUrl,
        );
        final infoCover = _usableCoverUrl(info['coverUrl']);
        final intro = info['intro']?.trim() ?? '';
        final lastFromInfo = info['lastChapter']?.trim() ?? '';
        updated = updated.copyWith(
          coverUrl: infoCover ?? updated.coverUrl,
          description: intro.isNotEmpty ? intro : updated.description,
          lastChapter: lastFromInfo.isNotEmpty
              ? lastFromInfo
              : updated.lastChapter,
        );
      } catch (e, st) {
        debugPrint('换源后拉取详情封面失败: $e\n$st');
      }
    }

    if (shelf != null) {
      await _repository.insert(updated);
      _books = await _repository.getAll();
    }
    if (_currentChapters.isNotEmpty &&
        _currentChapters.first.bookId == updated.id) {
      _currentChapters = [];
    }
    notifyListeners();
    return updated;
  }

  /// 自动换源 — 对齐 Jingshiro `ReadBookViewModel.autoChangeSource`：
  /// 并发精确搜索，依次验证目录和当前章正文，采用首个完整可读结果。
  Future<Book?> autoChangeSource(
    Book current, {
    required List<BookSource> sources,
    int concurrency = 4,
  }) async {
    final candidates = sources
        .where(
          (source) =>
              source.enabled &&
              source.bookSourceUrl.isNotEmpty &&
              source.bookSourceUrl != current.bookSourceUrl,
        )
        .toList();
    if (candidates.isEmpty) return null;

    final result =
        Completer<({Book book, BookSource source, List<Chapter> toc})?>();
    var remaining = candidates.length;
    var cursor = 0;
    final workers = List.generate(concurrency.clamp(1, candidates.length), (
      _,
    ) async {
      while (true) {
        final index = cursor++;
        if (index >= candidates.length || result.isCompleted) return;
        final source = candidates[index];
        final found = await _probeAutoSource(current, source);
        if (found != null && !result.isCompleted) {
          result.complete(found);
          return;
        }
        remaining--;
        if (remaining == 0 && !result.isCompleted) {
          result.complete(null);
          return;
        }
      }
    });
    unawaited(Future.wait(workers));

    final found = await result.future;
    if (found == null) return null;
    final oldChapters = List<Chapter>.from(_currentChapters);
    final updated = await changeSource(
      current,
      found.book,
      source: found.source,
    );
    final remapped = found.toc
        .asMap()
        .entries
        .map(
          (entry) => Chapter(
            id: Chapter.idFor(
              bookId: updated.id,
              url: entry.value.url,
              index: entry.key,
            ),
            bookId: updated.id,
            title: entry.value.title,
            index: entry.key,
            url: entry.value.url,
            isVolume: entry.value.isVolume,
            isVip: entry.value.isVip,
            isPay: entry.value.isPay,
            tag: entry.value.tag,
            baseUrl: entry.value.baseUrl,
          ),
        )
        .toList();
    final migrated = await _migrateReadingProgress(
      updated,
      oldChapters: oldChapters,
      newChapters: remapped,
    );
    _currentChapters = _tocViewList(remapped);
    ReadBook.instance.open(
      currentBook: migrated.book,
      source: found.source,
      chapterList: _currentChapters,
      startIndex: migrated.progress.chapterIndex,
    );
    if (_books.any((book) => book.id == updated.id)) {
      try {
        await _repository.insertChapters(_currentChapters);
      } catch (e) {
        debugPrint('自动换源目录落库失败（内存目录仍可用）: $e');
      }
    }
    notifyListeners();
    return updated;
  }

  Future<({Book book, BookSource source, List<Chapter> toc})?> _probeAutoSource(
    Book current,
    BookSource source,
  ) async {
    try {
      final results = await _sourceService.search(source, current.name);
      final books = _sourceService.resultsToBooks(
        results,
        source.bookSourceUrl,
      );
      Book? matched;
      for (final book in books) {
        final sameName = book.name.trim() == current.name.trim();
        final author = current.author.trim();
        if (sameName &&
            (author.isEmpty ||
                author == '未知作者' ||
                book.author.trim() == author)) {
          matched = book;
          break;
        }
      }
      if (matched == null) return null;
      final toc = await _sourceService.getChapters(matched, source: source);
      if (toc.isEmpty) return null;
      final index = current.durChapterIndex.clamp(0, toc.length - 1);
      final probe = await _sourceService.getChapterContent(
        toc[index].url,
        source: source,
      );
      if (ReadBook.shouldSkipCache(probe)) return null;
      return (book: matched, source: source, toc: toc);
    } catch (e) {
      debugPrint('自动换源跳过 ${source.bookSourceUrl}: $e');
      return null;
    }
  }

  /// 添加书籍到书架
  Future<void> addBook(Book book) async {
    await _bookshelfBookLifecycleController.addBook(book);
    _books = await _repository.getAll();
    await _refreshShelfChapterMetaFor(book.id);
    notifyListeners();
  }

  /// 从书架移除
  Future<void> removeBook(String bookId) async {
    await _bookshelfBookLifecycleController.removeBook(bookId);
    _shelfChapterMeta.remove(bookId);
    _books = await _repository.getAll();
    notifyListeners();
  }

  /// 批量从书架移除
  Future<void> removeBooks(Iterable<String> bookIds) async {
    for (final id in bookIds) {
      await _bookshelfBookLifecycleController.removeBook(id);
      _shelfChapterMeta.remove(id);
    }
    _books = await _repository.getAll();
    notifyListeners();
  }

  /// 批量更新分组
  Future<void> updateBooksGroup(Iterable<String> bookIds, String group) async {
    _books = await _bookshelfGroupController.updateBooksGroup(bookIds, group);
    notifyListeners();
  }

  /// 更新阅读进度（[durChapterIndex] 有值时 upsert 整书以持久化章索引）
  Future<void> updateProgress(
    String bookId,
    double progress,
    String? chapter, {
    int pageIndex = 0,
    int? durChapterIndex,
  }) async {
    // 有章索引时走整书 upsert（FRB updateProgress 尚未带 durChapterIndex）
    if (durChapterIndex != null) {
      final existing = findBookById(bookId);
      if (existing != null) {
        await _repository.insert(
          existing.copyWith(
            progress: progress,
            currentChapter: chapter,
            currentPageIndex: pageIndex,
            durChapterIndex: durChapterIndex,
          ),
        );
        _books = await _repository.getAll();
        await _refreshShelfChapterMetaFor(bookId);
        notifyListeners();
        return;
      }
    }
    await _repository.updateProgress(
      bookId,
      progress,
      chapter,
      pageIndex: pageIndex,
    );
    _books = await _repository.getAll();
    await _refreshShelfChapterMetaFor(bookId);
    notifyListeners();
  }

  /// 批量拉取 WebDAV 进度，并按原版规则只覆盖领先的本地书籍。
  Future<int> downloadAllBookProgress({
    required BatchBookProgressSyncPort sync,
  }) async {
    final books = List<Book>.from(_books);
    return sync.downloadAllBookProgress(
      books: books,
      apply: (book, remote) async {
        final total = book.totalChapterNum;
        final progress = total > 0
            ? ((remote.durChapterIndex + 1) / total).clamp(0.0, 1.0)
            : book.progress;
        await updateProgress(
          book.id,
          progress,
          remote.durChapterTitle ?? book.currentChapter,
          pageIndex: remote.durChapterPos,
          durChapterIndex: remote.durChapterIndex,
        );
      },
    );
  }

  /// 更新书籍分组
  Future<void> updateBookGroup(String bookId, String group) async {
    _books = await _bookshelfGroupController.updateBookGroup(bookId, group);
    notifyListeners();
  }

  /// 更新读完/N刷轮次（upsert 整书字段）
  Future<void> updateReadIteration(Book book, int readIteration) async {
    final next = book.copyWith(readIteration: readIteration);
    await _repository.insert(next);
    _books = await _repository.getAll();
    notifyListeners();
  }

  /// 按 id 取书架上的书（阅读器模拟追读等）
  Book? findBookById(String bookId) {
    for (final b in _books) {
      if (b.id == bookId) return b;
    }
    return null;
  }

  /// 更新模拟追读字段（写入 Book / DB，进入备份 JSON）
  Future<Book> updateSimulatedReading(
    Book book, {
    required bool enabled,
    required String startDate,
    required int startChapter,
    required int dailyChapters,
  }) async {
    final base = findBookById(book.id) ?? book;
    final next = base.copyWith(
      simReadEnabled: enabled,
      simReadStartDate: startDate,
      simReadStartChapter: startChapter < 0 ? 0 : startChapter,
      simReadDailyChapters: dailyChapters < 1 ? 3 : dailyChapters.clamp(1, 999),
    );
    await _repository.insert(next);
    _books = await _repository.getAll();
    notifyListeners();
    return findBookById(book.id) ?? next;
  }

  // ── 下载缓存 ──

  void cancelDownload() {
    _cancelRequested = true;
  }

  Future<String> downloadChapter(Chapter chapter, BookSource source) async {
    final bookId = chapter.bookId;
    final content = await ReadBook.instance.loadChapterContent(
      chapter: chapter,
      source: source,
      bookId: bookId,
      saveCache: true,
    );
    await _repository.saveChapterContent(chapter.id, content);
    return content;
  }

  Future<void> downloadAllChapters(
    String bookId,
    List<Chapter> chapters,
    BookSource source, {
    int concurrency = 1,
  }) async {
    _isDownloading = true;
    _downloadBookId = bookId;
    _downloadTotal = chapters.length;
    _downloadCompleted = 0;
    _cancelRequested = false;
    notifyListeners();

    await _repository.insertChapters(chapters);

    final workers = concurrency.clamp(1, 8);
    var next = 0;
    Future<void> worker() async {
      while (!_cancelRequested) {
        final i = next++;
        if (i >= chapters.length) break;
        final chapter = chapters[i];
        try {
          await downloadChapter(chapter, source);
        } catch (e) {
          debugPrint('  ✗ 下载失败: ${chapter.title} — $e');
        }
        _downloadCompleted++;
        notifyListeners();
      }
    }

    await Future.wait(List.generate(workers, (_) => worker()));

    _isDownloading = false;
    _downloadBookId = '';
    if (_currentChapters.isNotEmpty) {
      final localChapters = await _repository.getChapters(bookId);
      final downloadedIds = localChapters
          .where((c) => c.isDownloaded)
          .map((c) => c.id)
          .toSet();
      _currentChapters = _currentChapters
          .map(
            (c) => Chapter(
              id: c.id,
              bookId: c.bookId,
              title: c.title,
              index: c.index,
              url: c.url,
              isVolume: c.isVolume,
              isVip: c.isVip,
              isPay: c.isPay,
              tag: c.tag,
              baseUrl: c.baseUrl,
              isDownloaded: downloadedIds.contains(c.id) || c.isDownloaded,
              content: c.content,
            ),
          )
          .toList();
    }
    notifyListeners();
  }

  Future<String> loadChapterContentCached(
    String url, {
    required BookSource source,
    String? chapterId,
    String? bookId,
  }) async {
    if (chapterId == null) {
      return loadChapterContent(url, source: source);
    }
    final chapter = _currentChapters.firstWhere(
      (c) => c.id == chapterId,
      orElse: () => Chapter(
        id: chapterId,
        bookId: bookId ?? '',
        title: '',
        index: 0,
        url: url,
      ),
    );
    return ReadBook.instance.loadChapterContent(
      chapter: chapter,
      source: source,
      bookId: bookId ?? chapter.bookId,
      saveCache: true,
    );
  }

  // ── 章节操作 ──

  /// 加载目录（对齐 Legado：本地数据库即目录 UI，联网更新不挡首屏）
  ///
  /// - 本地已有章节且 [forceRefresh]=false：立刻展示；默认不后台联网
  /// - [backgroundRefresh]=true：本地展示后静默更新（书架下拉等可开）
  /// - 本地为空或 [forceRefresh]=true：阻塞等待网络目录并落库
  Future<void> loadChapters(
    Book book, {
    required BookSource source,
    bool forceRefresh = false,
    bool backgroundRefresh = false,
  }) async {
    // 内存命中：同一本书重复进详情/目录直接秒开（对齐 Legado 内存态）
    final currentSourceUrl = ReadBook.instance.bookSource?.bookSourceUrl;
    if (!forceRefresh &&
        _currentChapters.isNotEmpty &&
        _currentChapters.first.bookId == book.id &&
        currentSourceUrl == source.bookSourceUrl) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    // 强制刷新不与旧请求合并；非强制时与同书进行中的加载共用
    final loadKey = tocLoadKey(
      bookId: book.id,
      sourceUrl: source.bookSourceUrl,
    );
    if (!forceRefresh) {
      final pending = _inflightTocLoads[loadKey];
      if (pending != null) return pending;
    }

    final future = _loadChaptersBody(
      book,
      source: source,
      forceRefresh: forceRefresh,
      backgroundRefresh: backgroundRefresh,
    );
    _inflightTocLoads[loadKey] = future;
    try {
      await future;
    } finally {
      if (identical(_inflightTocLoads[loadKey], future)) {
        _inflightTocLoads.remove(loadKey);
      }
    }
  }

  Future<void> _loadChaptersBody(
    Book book, {
    required BookSource source,
    bool forceRefresh = false,
    bool backgroundRefresh = false,
  }) async {
    final gen = ++_tocLoadGen;
    final localChapters = await _repository.getChapters(book.id);
    final hasLocal = localChapters.isNotEmpty;

    if (hasLocal && !forceRefresh) {
      // 元数据即可展示；文件勾选异步补，不挡首屏
      _currentChapters = _tocViewList(localChapters);
      final migrated = await _migrateReadingProgress(
        book,
        oldChapters: localChapters,
        newChapters: _currentChapters,
      );
      _isLoading = false;
      notifyListeners();
      ReadBook.instance.open(
        currentBook: migrated.book,
        source: source,
        chapterList: _currentChapters,
        startIndex: migrated.progress.chapterIndex,
      );
      unawaited(_enrichDownloadedFromFiles(book.id, gen));
      if (backgroundRefresh) {
        unawaited(_refreshTocFromNetwork(book, source, gen));
      }
      return;
    }

    _isLoading = true;
    if (!hasLocal) {
      _currentChapters = [];
    }
    notifyListeners();
    try {
      await _refreshTocFromNetwork(book, source, gen);
    } finally {
      if (gen == _tocLoadGen) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _refreshTocFromNetwork(
    Book book,
    BookSource source,
    int gen,
  ) async {
    _isRefreshingToc = true;
    notifyListeners();
    try {
      final remote = await _sourceService.getChapters(book, source: source);
      if (gen != _tocLoadGen) return;

      final local = await _repository.getChapters(book.id);
      final merged = _mergeTocWithLocal(
        remote,
        local,
        reverseToc: book.readConfig.reverseToc,
      );

      // 先写入内存，避免「已拉到目录但落库失败」时界面仍空白
      if (gen != _tocLoadGen) return;
      _currentChapters = _tocViewList(merged);
      final migrated = await _migrateReadingProgress(
        book,
        oldChapters: local,
        newChapters: _currentChapters,
      );
      ReadBook.instance.open(
        currentBook: migrated.book,
        source: source,
        chapterList: _currentChapters,
        startIndex: migrated.progress.chapterIndex,
      );
      notifyListeners();

      // 仅书架内的书落库（chapters.bookId → books.id 外键）；搜索预览不写 books
      final onShelf = _books.any((b) => b.id == book.id);
      if (onShelf) {
        // 防御元数据；不把正文再次塞进 upsert JSON
        final meta = merged
            .map(
              (c) => Chapter(
                id: c.id,
                bookId: book.id,
                title: c.title,
                index: c.index,
                url: c.url,
                isVolume: c.isVolume,
                isVip: c.isVip,
                isPay: c.isPay,
                tag: c.tag,
                baseUrl: c.baseUrl,
                isDownloaded: c.isDownloaded,
                content: c.content,
              ),
            )
            .toList();
        try {
          await _repository.insertChapters(meta);
          if (gen != _tocLoadGen) return;
          final shelfBook = findBookById(book.id);
          if (shelfBook != null && shelfBook.totalChapterNum != merged.length) {
            final next = shelfBook.copyWith(totalChapterNum: merged.length);
            await _repository.insert(next);
            final i = _books.indexWhere((b) => b.id == book.id);
            if (i >= 0) _books[i] = next;
          }
          final saved = await _repository.getChapters(book.id);
          if (saved.isNotEmpty) {
            _currentChapters = _tocViewList(saved);
            ReadBook.instance.open(
              currentBook: migrated.book,
              source: source,
              chapterList: _currentChapters,
              startIndex: migrated.progress.chapterIndex,
            );
            await _refreshShelfChapterMetaFor(book.id);
            notifyListeners();
          }
        } catch (e, st) {
          // 内存目录已可用；落库失败不吞掉预览
          debugPrint('目录落库失败（已保留内存目录）: $e\n$st');
        }
      }

      unawaited(_enrichDownloadedFromFiles(book.id, gen));
    } catch (e, st) {
      final friendly = SiteBusyGuard.friendlyMessage(e);
      debugPrint('目录刷新失败: $friendly\n$st');
      if (gen == _tocLoadGen && _currentChapters.isEmpty) {
        throw Exception(friendly);
      }
      // 已有本地/内存目录时后台刷新失败不打断阅读
    } finally {
      if (gen == _tocLoadGen) {
        _isRefreshingToc = false;
        notifyListeners();
      }
    }
  }

  /// 用章节 URL 合并本地下载状态，避免刷新目录清掉已缓存正文标记
  List<Chapter> _mergeTocWithLocal(
    List<Chapter> remote,
    List<Chapter> local, {
    bool reverseToc = false,
  }) {
    final merged = Chapter.mergeWithLocal(remote, local);
    final ordered = reverseToc ? merged.reversed.toList() : merged;
    return ordered.asMap().entries.map((entry) {
      final chapter = entry.value;
      return Chapter(
        id: chapter.id,
        bookId: chapter.bookId,
        title: chapter.title,
        index: entry.key,
        url: chapter.url,
        isVolume: chapter.isVolume,
        isVip: chapter.isVip,
        isPay: chapter.isPay,
        tag: chapter.tag,
        baseUrl: chapter.baseUrl,
        isDownloaded: chapter.isDownloaded,
        content: chapter.content,
      );
    }).toList();
  }

  /// 目录列表元数据（不含正文）
  List<Chapter> _tocViewList(List<Chapter> chapters) {
    return chapters.asMap().entries.map((entry) {
      final c = entry.value;
      return Chapter(
        id: c.id,
        bookId: c.bookId,
        title: c.title,
        index: entry.key,
        url: c.url,
        isVolume: c.isVolume,
        isVip: c.isVip,
        isPay: c.isPay,
        tag: c.tag,
        baseUrl: c.baseUrl,
        isDownloaded: c.isDownloaded,
        content: c.content,
      );
    }).toList();
  }

  /// 异步用文件缓存补全勾选，不阻塞目录首屏
  Future<void> _enrichDownloadedFromFiles(String bookId, int gen) async {
    final fileCached = await _contentCache.listChapterIds(bookId);
    if (gen != _tocLoadGen) return;
    var changed = false;
    final cleared = <Chapter>[];
    final next = _currentChapters.map((c) {
      final hasFile = fileCached.contains(
        _contentCache.sanitizeChapterId(c.id),
      );
      if (c.isDownloaded == hasFile) return c;
      changed = true;
      if (!hasFile) cleared.add(c);
      return Chapter(
        id: c.id,
        bookId: c.bookId,
        title: c.title,
        index: c.index,
        url: c.url,
        isVolume: c.isVolume,
        isVip: c.isVip,
        isPay: c.isPay,
        tag: c.tag,
        baseUrl: c.baseUrl,
        isDownloaded: hasFile,
        content: c.content,
      );
    }).toList();
    if (!changed || gen != _tocLoadGen) return;
    _currentChapters = next;
    if (_books.any((book) => book.id == bookId)) {
      try {
        await _repository.insertChapters(next);
        for (final chapter in cleared) {
          await _repository.clearChapterContent(chapter);
        }
      } catch (e) {
        debugPrint('章节文件缓存元数据回写失败: $e');
      }
    }
    notifyListeners();
  }

  /// 标记章节已缓存（文件/正文拉取成功后更新目录勾选）
  void markChapterDownloaded(String chapterId) {
    final i = _currentChapters.indexWhere((c) => c.id == chapterId);
    if (i < 0 || _currentChapters[i].isDownloaded) return;
    final c = _currentChapters[i];
    _currentChapters = List<Chapter>.from(_currentChapters);
    _currentChapters[i] = Chapter(
      id: c.id,
      bookId: c.bookId,
      title: c.title,
      index: c.index,
      url: c.url,
      isVolume: c.isVolume,
      isVip: c.isVip,
      isPay: c.isPay,
      tag: c.tag,
      baseUrl: c.baseUrl,
      isDownloaded: true,
      content: c.content,
    );
    notifyListeners();
  }

  Future<String> loadChapterContent(
    String url, {
    required BookSource source,
    String? chapterId,
    String? bookId,
  }) async {
    if (chapterId != null) {
      final chapter = _currentChapters.firstWhere(
        (c) => c.id == chapterId,
        orElse: () => Chapter(
          id: chapterId,
          bookId: bookId ?? '',
          title: '',
          index: 0,
          url: url,
        ),
      );
      return ReadBook.instance.loadChapterContent(
        chapter: chapter,
        source: source,
        bookId: bookId ?? chapter.bookId,
      );
    }
    final raw = await _sourceService.getChapterContent(url, source: source);
    if (ReadBook.instance.enableReplace) {
      return ReadBook.instance.processContent(raw);
    }
    return raw;
  }

  Future<List<Chapter>> getLocalChapters(String bookId) async {
    return await _repository.getChapters(bookId);
  }
}
