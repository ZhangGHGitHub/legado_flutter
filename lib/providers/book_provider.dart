import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../models/book_source.dart';
import '../models/chapter.dart';
import '../database/database_helper.dart';
import '../services/book_source_service.dart';
import '../services/local_book_service.dart';
import '../services/replace_service.dart';

/// 书籍管理 Provider — 书架、阅读、章节、下载缓存
class BookProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final BookSourceService _sourceService = BookSourceService();
  final LocalBookService _localService = LocalBookService();
  final ReplaceService _replaceService = ReplaceService();

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
    _books = await _db.getBooks();
    notifyListeners();
  }

  /// 更新阅读进度
  Future<void> updateProgress(String bookId, double progress, String? chapter, {int pageIndex = 0}) async {
    await _db.updateBookProgress(bookId, progress, chapter, pageIndex: pageIndex);
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
        await addBook(book);
      }
      return book;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── 下载缓存 ──

  /// 取消当前下载
  void cancelDownload() {
    _cancelRequested = true;
  }

  /// 下载单个章节正文并保存到数据库
  Future<String> downloadChapter(Chapter chapter, BookSource source) async {
    final raw = await _sourceService.getChapterContent(chapter.url, source: source);
    final content = _replaceService.apply(raw);
    await _db.saveChapterContent(chapter.id, content);
    return content;
  }

  /// 批量下载所有未缓存章节
  Future<void> downloadAllChapters(String bookId, List<Chapter> chapters, BookSource source) async {
    _isDownloading = true;
    _downloadBookId = bookId;
    _downloadTotal = chapters.length;
    _downloadCompleted = 0;
    _cancelRequested = false;
    notifyListeners();

    // 先保存章节列表（确保 id/索引正确）
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
    // 刷新已下载状态
    if (_currentChapters.isNotEmpty) {
      final localChapters = await _db.getChapters(bookId);
      final downloadedIds = localChapters
          .where((c) => c.isDownloaded)
          .map((c) => c.id)
          .toSet();
      _currentChapters = _currentChapters.map((c) => Chapter(
        id: c.id,
        bookId: c.bookId,
        title: c.title,
        index: c.index,
        url: c.url,
        isDownloaded: downloadedIds.contains(c.id),
        content: c.content,
      )).toList();
    }
    notifyListeners();
  }

  /// 加载正文并自动缓存到本地
  Future<String> loadChapterContentCached(String url, {required BookSource source, String? chapterId}) async {
    final content = await loadChapterContent(url, source: source);
    if (chapterId != null && content.isNotEmpty && !content.startsWith('⚠️') && !content.startsWith('（加载失败')) {
      await _db.saveChapterContent(chapterId, content);
    }
    return content;
  }

  // ── 章节操作 ──

  /// 加载章节列表（自动合并已缓存状态）
  Future<void> loadChapters(Book book, {required BookSource source}) async {
    _isLoading = true;
    _currentChapters = [];
    notifyListeners();
    try {
      _currentChapters = await _sourceService.getChapters(book, source: source);
      // 合并已下载状态
      final localChapters = await _db.getChapters(book.id);
      final downloadedIds = localChapters
          .where((c) => c.isDownloaded)
          .map((c) => c.id)
          .toSet();
      _currentChapters = _currentChapters.map((c) => Chapter(
        id: c.id,
        bookId: c.bookId,
        title: c.title,
        index: c.index,
        url: c.url,
        isDownloaded: downloadedIds.contains(c.id),
        content: c.content,
      )).toList();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 加载章节正文（自动应用替换净化规则）
  Future<String> loadChapterContent(String url, {required BookSource source}) async {
    final content = await _sourceService.getChapterContent(url, source: source);
    return _replaceService.apply(content);
  }

  /// 从数据库获取已缓存的章节列表
  Future<List<Chapter>> getLocalChapters(String bookId) async {
    return await _db.getChapters(bookId);
  }
}
