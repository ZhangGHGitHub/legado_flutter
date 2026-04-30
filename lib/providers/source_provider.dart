import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../models/book.dart';
import '../models/book_source.dart';
import '../database/database_helper.dart';
import '../services/book_source_service.dart';

/// 书源管理 Provider — 书源 CRUD、搜索
class SourceProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final BookSourceService _sourceService = BookSourceService();

  List<BookSource> _sources = [];
  Map<String, List<Book>> _searchResults = {};
  bool _isLoading = false;
  String _statusMessage = '';

  List<BookSource> get sources => _sources;
  Map<String, List<Book>> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String get statusMessage => _statusMessage;

  /// 加载书源
  Future<void> loadSources() async {
    _sources = await _db.getBookSources();
    notifyListeners();
  }

  /// 添加单个书源
  Future<void> addSource(BookSource source) async {
    await _db.insertBookSource(source);
    _sources = await _db.getBookSources();
    notifyListeners();
  }

  /// 从 JSON 文本导入
  Future<void> importSources(String jsonText) async {
    _isLoading = true;
    notifyListeners();
    try {
      final list = jsonDecode(jsonText);
      if (list is! List) return;
      final sources = list.whereType<Map<String, dynamic>>()
          .map((e) => BookSource.fromJson(e)).toList();
      if (sources.isNotEmpty) {
        await _db.insertBookSources(sources);
        _sources = await _db.getBookSources();
      }
    } catch (e) {
      debugPrint('  ✗ JSON 解析失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 从文件导入
  Future<void> importSourcesFromFile() async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return;
      final file = File(result.files.single.path!);
      final jsonText = await file.readAsString();
      await importSources(jsonText);
    } catch (e) {
      debugPrint('  ✗ 文件导入失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 从 URL 导入
  Future<bool> importSourcesFromUrl(String url) async {
    _isLoading = true;
    notifyListeners();
    try {
      final sources = await BookSourceService.fetchSourcesFromUrl(url);
      if (sources.isEmpty) return false;
      await _db.insertBookSources(sources);
      _sources = await _db.getBookSources();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('  ✗ 从 URL 导入失败: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 启用/禁用书源
  Future<void> toggleSource(String sourceUrl, bool enabled) async {
    await _db.toggleSource(sourceUrl, enabled);
    _sources = await _db.getBookSources();
    notifyListeners();
  }

  /// 删除书源
  Future<void> deleteSource(String sourceUrl) async {
    await _db.deleteSource(sourceUrl);
    _sources = await _db.getBookSources();
    notifyListeners();
  }

  /// 更新单个书源
  Future<void> updateSource(BookSource source) async {
    await _db.updateBookSource(source);
    _sources = await _db.getBookSources();
    notifyListeners();
  }

  // ── 搜索 ──

  /// 联合搜索所有已启用书源
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

  /// 根据书籍查找对应的书源（用于阅读）
  BookSource? findSourceForBook(Book book) {
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
}
