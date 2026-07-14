import 'dart:async';

import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../models/book_source.dart';
import '../models/chapter.dart';
import '../database/database_helper.dart';
import '../help/book_help.dart';
import '../help/content_processor.dart';
import '../model/read_book.dart';
import '../services/book_source_service.dart';
import '../services/local_book_service.dart';

/// 书籍管理 Provider — 书架、阅读、章节、下载缓存
class BookProvider extends ChangeNotifier {
  BookProvider() {
    ReadBook.instance.configure(
      sourceService: _sourceService,
      db: _db,
      processor: ContentProcessor.instance,
    );
  }

  final DatabaseHelper _db = DatabaseHelper();
  final BookSourceService _sourceService = BookSourceService();
  final LocalBookService _localService = LocalBookService();

  List<Book> _books = [];
  List<Chapter> _currentChapters = [];
  bool _isLoading = false;

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

  List<Book> get books => _books;
  List<Chapter> get currentChapters => _currentChapters;
  bool get isLoading => _isLoading;
  bool get isDownloading => _isDownloading;
  int get downloadTotal => _downloadTotal;
  int get downloadCompleted => _downloadCompleted;
  String get downloadBookId => _downloadBookId;
  double get downloadProgress =>
      _downloadTotal > 0 ? _downloadCompleted / _downloadTotal : 0.0;

  ReadBook get readBook => ReadBook.instance;

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
        id: '${book.id}_ch_${e.key}',
        bookId: book.id,
        title: c.title,
        index: e.key,
        url: c.url,
        isDownloaded: c.isDownloaded,
      );
    }).toList();
    await _db.insertChapters(list);
    _currentChapters = list;
    notifyListeners();
  }

  /// 加载书架
  Future<void> loadBooks() async {
    _books = await _db.getBooks();
    notifyListeners();
  }

  /// 添加书籍到书架
  Future<void> addBook(Book book) async {
    await _db.insertBook(book);
    _books = await _db.getBooks();
    notifyListeners();
  }

  /// 从书架移除
  Future<void> removeBook(String bookId) async {
    await _db.deleteBook(bookId);
    await BookHelp.clearBookCache(bookId);
    _books = await _db.getBooks();
    notifyListeners();
  }

  /// 更新阅读进度
  Future<void> updateProgress(
    String bookId,
    double progress,
    String? chapter, {
    int pageIndex = 0,
  }) async {
    await _db.updateBookProgress(
      bookId,
      progress,
      chapter,
      pageIndex: pageIndex,
    );
    _books = await _db.getBooks();
    notifyListeners();
  }

  /// 更新书籍分组
  Future<void> updateBookGroup(String bookId, String group) async {
    await _db.updateBookGroup(bookId, group);
    _books = await _db.getBooks();
    notifyListeners();
  }

  /// 更新读完/N刷轮次（upsert 整书字段）
  Future<void> updateReadIteration(Book book, int readIteration) async {
    final next = book.copyWith(readIteration: readIteration);
    await _db.insertBook(next);
    _books = await _db.getBooks();
    notifyListeners();
  }

  /// 从本地导入 TXT/EPUB
  Future<Book?> importLocalBook() async {
    _isLoading = true;
    notifyListeners();
    try {
      final book = await _localService.importFromFile();
      if (book != null) {
        _books = await _db.getBooks();
        notifyListeners();
      }
      return book;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
    await _db.saveChapterContent(chapter.id, content);
    return content;
  }

  Future<void> downloadAllChapters(
    String bookId,
    List<Chapter> chapters,
    BookSource source,
  ) async {
    _isDownloading = true;
    _downloadBookId = bookId;
    _downloadTotal = chapters.length;
    _downloadCompleted = 0;
    _cancelRequested = false;
    notifyListeners();

    await _db.insertChapters(chapters);

    for (final chapter in chapters) {
      if (_cancelRequested) break;

      try {
        await downloadChapter(chapter, source);
        _downloadCompleted++;
        notifyListeners();
      } catch (e) {
        debugPrint('  ✗ 下载失败: ${chapter.title} — $e');
        _downloadCompleted++;
        notifyListeners();
      }
    }

    _isDownloading = false;
    _downloadBookId = '';
    if (_currentChapters.isNotEmpty) {
      final localChapters = await _db.getChapters(bookId);
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
              isDownloaded: downloadedIds.contains(c.id),
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
    if (!forceRefresh &&
        _currentChapters.isNotEmpty &&
        _currentChapters.first.bookId == book.id) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    final gen = ++_tocLoadGen;
    final localChapters = await _db.getChapters(book.id);
    final hasLocal = localChapters.isNotEmpty;

    if (hasLocal && !forceRefresh) {
      // 元数据即可展示；文件勾选异步补，不挡首屏
      _currentChapters = _tocViewList(localChapters);
      _isLoading = false;
      notifyListeners();
      ReadBook.instance.open(
        currentBook: book,
        source: source,
        chapterList: _currentChapters,
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

      final local = await _db.getChapters(book.id);
      final merged = _mergeTocWithLocal(remote, local);
      // 只落目录元数据 + isDownloaded，不把正文再次塞进 upsert JSON
      await _db.insertChapters(
        merged
            .map(
              (c) => Chapter(
                id: c.id,
                bookId: c.bookId,
                title: c.title,
                index: c.index,
                url: c.url,
                isDownloaded: c.isDownloaded,
              ),
            )
            .toList(),
      );
      if (gen != _tocLoadGen) return;

      final saved = await _db.getChapters(book.id);
      _currentChapters = _tocViewList(saved.isNotEmpty ? saved : merged);
      unawaited(_enrichDownloadedFromFiles(book.id, gen));

      ReadBook.instance.open(
        currentBook: book,
        source: source,
        chapterList: _currentChapters,
      );
      notifyListeners();
    } catch (e, st) {
      debugPrint('目录刷新失败: $e\n$st');
      if (gen == _tocLoadGen && _currentChapters.isEmpty) {
        rethrow;
      }
      // 已有本地目录时后台刷新失败不打断阅读
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
    List<Chapter> local,
  ) {
    final byUrl = <String, Chapter>{
      for (final c in local)
        if (c.url.isNotEmpty) c.url: c,
    };
    final byId = <String, Chapter>{for (final c in local) c.id: c};

    return remote.map((r) {
      final old = (r.url.isNotEmpty ? byUrl[r.url] : null) ?? byId[r.id];
      if (old == null) return r;
      final downloaded = old.isDownloaded;
      return Chapter(
        id: r.id,
        bookId: r.bookId,
        title: r.title,
        index: r.index,
        url: r.url,
        isDownloaded: downloaded,
      );
    }).toList();
  }

  /// 目录列表元数据（不含正文）
  List<Chapter> _tocViewList(List<Chapter> chapters) {
    return chapters
        .map(
          (c) => Chapter(
            id: c.id,
            bookId: c.bookId,
            title: c.title,
            index: c.index,
            url: c.url,
            isDownloaded: c.isDownloaded,
          ),
        )
        .toList();
  }

  /// 异步用文件缓存补全勾选，不阻塞目录首屏
  Future<void> _enrichDownloadedFromFiles(String bookId, int gen) async {
    final fileCached = await BookHelp.listCachedChapterIds(bookId);
    if (gen != _tocLoadGen || fileCached.isEmpty) return;
    var changed = false;
    final next = _currentChapters.map((c) {
      if (c.isDownloaded) return c;
      if (!fileCached.contains(BookHelp.sanitizeId(c.id))) return c;
      changed = true;
      return Chapter(
        id: c.id,
        bookId: c.bookId,
        title: c.title,
        index: c.index,
        url: c.url,
        isDownloaded: true,
      );
    }).toList();
    if (!changed || gen != _tocLoadGen) return;
    _currentChapters = next;
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
      isDownloaded: true,
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
    return ContentProcessor.instance.getContent(raw);
  }

  Future<List<Chapter>> getLocalChapters(String bookId) async {
    return await _db.getChapters(bookId);
  }
}
