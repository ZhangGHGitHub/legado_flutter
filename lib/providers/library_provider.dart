import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../models/book_source.dart';
import '../models/chapter.dart';
import '../models/replace_rule.dart';
import '../database/database_helper.dart';
import '../services/book_source_service.dart';
import '../services/local_book_service.dart';
import '../services/replace_service.dart';

/// 全局状态管理 - 管理书籍库、书源、搜索、本地导入、替换规则
class LibraryProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final BookSourceService _sourceService = BookSourceService();
  final LocalBookService _localService = LocalBookService();
  final ReplaceService _replaceService = ReplaceService();

  // ── 状态 ──
  List<Book> _books = [];
  List<BookSource> _sources = [];
  List<Chapter> _currentChapters = [];
  List<ReplaceRule> _replaceRules = [];
  Map<String, List<Book>> _searchResults = {};
  bool _isLoading = false;
  String _statusMessage = '';

  // ── Getter ──
  List<Book> get books => _books;
  List<BookSource> get sources => _sources;
  List<Chapter> get currentChapters => _currentChapters;
  List<ReplaceRule> get replaceRules => _replaceRules;
  Map<String, List<Book>> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String get statusMessage => _statusMessage;

  // ── 替换规则引擎暴露给阅读器 ──
  ReplaceService get replaceService => _replaceService;

  /// 初始化
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    _books = await _db.getBooks();
    _sources = await _db.getBookSources();
    _replaceRules = await _db.getReplaceRules();

    // 首次运行导入默认书源和替换规则
    if (_sources.isEmpty) {
      await _db.insertBookSources(BookSourceService.builtInSources());
      _sources = await _db.getBookSources();
    }
    if (_replaceRules.isEmpty) {
      await _db.insertReplaceRules(ReplaceService.builtInRules());
      _replaceRules = await _db.getReplaceRules();
    }

    // 加载替换规则到引擎
    _replaceService.loadRules(_replaceRules);

    _isLoading = false;
    notifyListeners();
  }

  // ═══════════════════ 书籍操作 ═══════════════════

  Future<void> addBook(Book book) async {
    await _db.insertBook(book);
    _books = await _db.getBooks();
    notifyListeners();
  }

  Future<void> removeBook(String bookId) async {
    await _db.deleteBook(bookId);
    _books = await _db.getBooks();
    notifyListeners();
  }

  Future<void> updateProgress(String bookId, double progress, String? chapter) async {
    await _db.updateBookProgress(bookId, progress, chapter);
    _books = await _db.getBooks();
    notifyListeners();
  }

  Future<Book?> importLocalBook() async {
    _isLoading = true;
    notifyListeners();
    try {
      final book = await _localService.importFromFile();
      if (book != null) {
        _books = await _db.getBooks();
      }
      _isLoading = false;
      notifyListeners();
      return book;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ═══════════════════ 书源操作 ═══════════════════

  Future<void> addSource(BookSource source) async {
    await _db.insertBookSource(source);
    _sources = await _db.getBookSources();
    notifyListeners();
  }

  Future<void> toggleSource(String url, bool enabled) async {
    await _db.toggleSource(url, enabled);
    _sources = await _db.getBookSources();
    notifyListeners();
  }

  Future<void> updateSource(BookSource source) async {
    await _db.updateBookSource(source);
    _sources = await _db.getBookSources();
    notifyListeners();
  }

  Future<void> deleteSource(String url) async {
    await _db.deleteSource(url);
    _sources = await _db.getBookSources();
    notifyListeners();
  }

  Future<void> importSources(String jsonText) async {
    try {
      final decoded = jsonDecode(jsonText);
      final list = decoded as List;
      final sources = list
          .map((e) => e is Map ? BookSource.fromJson(Map<String, dynamic>.from(e)) : null)
          .whereType<BookSource>()
          .toList();
      await _db.insertBookSources(sources);
      _sources = await _db.getBookSources();
      notifyListeners();
    } catch (e) {
      debugPrint('导入书源失败: $e');
    }
  }

  Future<void> importDefaultSources() async {
    await _db.insertBookSources(BookSourceService.builtInSources());
    _sources = await _db.getBookSources();
    notifyListeners();
  }

  /// 从 URL 导入书源（Legado 社区仓库）
  Future<bool> importSourcesFromUrl(String url) async {
    try {
      final sources = await BookSourceService.fetchSourcesFromUrl(url);
      if (sources.isEmpty) return false;
      await _db.insertBookSources(sources);
      _sources = await _db.getBookSources();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('从URL导入书源失败: $e');
      return false;
    }
  }

  // ═══════════════════ 搜索操作 ═══════════════════

  Future<void> searchAll(String keyword) async {
    if (keyword.isEmpty) return;
    _isLoading = true;
    _searchResults = {};
    _statusMessage = '正在搜索 "$keyword"...';
    notifyListeners();

    final enabledSources = await _db.getEnabledSources();
    debugPrint('📡 搜索 "$keyword"，共 ${enabledSources.length} 个书源');

    if (enabledSources.isEmpty) {
      _isLoading = false;
      _statusMessage = '没有启用的书源，请先导入书源';
      notifyListeners();
      return;
    }

    for (final source in enabledSources) {
      try {
        debugPrint('  ▶ 书源: ${source.bookSourceName} (${source.bookSourceUrl})');
        debugPrint('  ▸ rawSourceJson 长度=${source.rawSourceJson.length}, ruleSearchList="${source.ruleSearchList}", isJsonApi=${source.isJsonApiSource}');
        final results = await _sourceService.search(source, keyword);
        debugPrint('  ✓ ${source.bookSourceName}: ${results.length} 个结果');
        if (results.isNotEmpty) {
          _searchResults[source.bookSourceUrl] =
              _sourceService.resultsToBooks(results, source.bookSourceUrl);
        }
      } catch (e, stack) {
        debugPrint('  ✗ ${source.bookSourceName}: 出错 — $e');
        debugPrint('     $stack');
      }
    }

    _isLoading = false;
    _statusMessage = _searchResults.isEmpty
        ? '未找到结果'
        : '找到 ${_searchResults.values.fold(0, (s, l) => s + l.length)} 本书';
    notifyListeners();
  }

  /// 根据书籍查找对应的书源
  BookSource? _findSourceForBook(Book book) {
    if (book.bookSourceUrl.isNotEmpty) {
      for (final s in _sources) {
        if (s.bookSourceUrl == book.bookSourceUrl) return s;
      }
    }
    // 兼容旧数据: 按 book.id 前缀匹配
    for (final s in _sources) {
      if (book.id.startsWith(s.bookSourceUrl)) return s;
    }
    // 按 book.sourceUrl 匹配
    for (final s in _sources) {
      if (book.sourceUrl.startsWith(s.bookSourceUrl)) return s;
    }
    return null;
  }

  Future<void> loadChapters(Book book) async {
    _isLoading = true;
    _currentChapters = [];
    notifyListeners();
    final source = _findSourceForBook(book) ?? _sources.first;
    _currentChapters = await _sourceService.getChapters(book, source: source);
    _isLoading = false;
    notifyListeners();
  }

  /// 加载章节正文，自动匹配对应书源的规则
  Future<String> loadChapterContent(Book book, String url) async {
    final source = _findSourceForBook(book) ?? _sources.firstWhere(
      (s) => s.enabled,
      orElse: () => _sources.first,
    );
    final content = await _sourceService.getChapterContent(url, source: source);
    // 应用替换净化规则
    return _replaceService.apply(content);
  }

  Future<List<Chapter>> getLocalChapters(String bookId) async {
    return await _db.getChapters(bookId);
  }

  // ═══════════════════ 替换规则操作 ═══════════════════

  Future<void> saveReplaceRule(ReplaceRule rule) async {
    await _db.insertReplaceRule(rule);
    _replaceRules = await _db.getReplaceRules();
    _replaceService.loadRules(_replaceRules);
    notifyListeners();
  }

  Future<void> toggleReplaceRule(String id, bool enabled) async {
    await _db.toggleReplaceRule(id, enabled);
    _replaceRules = await _db.getReplaceRules();
    _replaceService.loadRules(_replaceRules);
    notifyListeners();
  }

  Future<void> deleteReplaceRule(String id) async {
    await _db.deleteReplaceRule(id);
    _replaceRules = await _db.getReplaceRules();
    _replaceService.loadRules(_replaceRules);
    notifyListeners();
  }

  Future<void> resetReplaceRules() async {
    // 删掉所有现有规则，重新导入默认
    final db = await _db.database;
    await db.delete('replace_rules');
    await _db.insertReplaceRules(ReplaceService.builtInRules());
    _replaceRules = await _db.getReplaceRules();
    _replaceService.loadRules(_replaceRules);
    notifyListeners();
  }
}
