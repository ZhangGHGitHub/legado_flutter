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

  Future<void> loadChapters(Book book, {required BookSource source}) async {
    _isLoading = true;
    _currentChapters = [];
    notifyListeners();
    try {
      _currentChapters = await _sourceService.getChapters(book, source: source);
      final localChapters = await _db.getChapters(book.id);
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

      ReadBook.instance.open(
        currentBook: book,
        source: source,
        chapterList: _currentChapters,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
