import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../models/book_source.dart';
import '../models/chapter.dart';
import '../database/database_helper.dart';
import '../services/book_source_service.dart';
import '../services/local_book_service.dart';
import '../services/replace_service.dart';

/// 书籍管理 Provider — 书架、阅读、章节
class BookProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final BookSourceService _sourceService = BookSourceService();
  final LocalBookService _localService = LocalBookService();
  final ReplaceService _replaceService = ReplaceService();

  List<Book> _books = [];
  List<Chapter> _currentChapters = [];
  bool _isLoading = false;

  List<Book> get books => _books;
  List<Chapter> get currentChapters => _currentChapters;
  bool get isLoading => _isLoading;

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
  Future<void> updateProgress(String bookId, double progress, String? chapter) async {
    await _db.updateBookProgress(bookId, progress, chapter);
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

  // ── 章节操作 ──

  /// 加载章节列表
  Future<void> loadChapters(Book book, {required BookSource source}) async {
    _isLoading = true;
    _currentChapters = [];
    notifyListeners();
    try {
      _currentChapters = await _sourceService.getChapters(book, source: source);
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
