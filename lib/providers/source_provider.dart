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

  /// 从 JSON 文本或书源订阅 URL 导入
  Future<bool> importSources(String jsonText) async {
    final text = _normalizeImportText(jsonText);
    if (text.isEmpty) return false;

    // 误将订阅 URL 粘贴到 JSON 框时，自动走网络拉取
    if (_looksLikeUrl(text)) {
      debugPrint('  ▸ 检测到书源 URL，自动拉取: $text');
      return importSourcesFromUrl(text);
    }

    _isLoading = true;
    notifyListeners();
    try {
      final decoded = jsonDecode(text);
      final list = _extractSourceList(decoded);
      if (list == null || list.isEmpty) {
        _statusMessage = '未找到有效书源数据';
        return false;
      }
      final sources = list
          .whereType<Map<String, dynamic>>()
          .map((e) => BookSource.fromJson(e))
          .toList();
      if (sources.isEmpty) {
        _statusMessage = '书源格式无效';
        return false;
      }
      await _db.insertBookSources(sources);
      _sources = await _db.getBookSources();
      _statusMessage = '已导入 ${sources.length} 个书源';
      return true;
    } catch (e) {
      debugPrint('  ✗ JSON 解析失败: $e');
      _statusMessage = 'JSON 解析失败，请检查格式或改用「从URL导入」';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  static String _normalizeImportText(String raw) {
    var text = raw.trim().replaceFirst('\uFEFF', '');
    // 仅粘贴 URL 时取首行（避免尾部多余空行/说明文字）
    final firstLine = text.split(RegExp(r'\r?\n')).first.trim();
    if (_looksLikeUrl(firstLine)) return firstLine;
    // 去掉 JSON 字符串式引号包裹
    if ((text.startsWith('"') && text.endsWith('"')) ||
        (text.startsWith("'") && text.endsWith("'"))) {
      text = text.substring(1, text.length - 1).trim();
    }
    return text;
  }

  static bool _looksLikeUrl(String text) {
    if (RegExp(r'^https?://', caseSensitive: false).hasMatch(text)) {
      return true;
    }
    final uri = Uri.tryParse(text);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  static List<dynamic>? _extractSourceList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map) {
      if (decoded.containsKey('bookSourceUrl') ||
          decoded.containsKey('bookSourceName')) {
        return [decoded];
      }
      for (final key in [
        'data',
        'sources',
        'result',
        'bookSources',
        'items',
        'records',
      ]) {
        final val = decoded[key];
        if (val is List) return val;
      }
    }
    return null;
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
      if (sources.isEmpty) {
        _statusMessage = 'URL 未返回有效书源，请检查链接或网络';
        return false;
      }
      await _db.insertBookSources(sources);
      _sources = await _db.getBookSources();
      _statusMessage = '已从 URL 导入 ${sources.length} 个书源';
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('  ✗ 从 URL 导入失败: $e');
      _statusMessage = '从 URL 获取书源失败: $e';
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

    // 并行搜索，单书源超时 20s，避免无效书源拖慢整体
    await Future.wait(
      enabledSources.map((source) => _searchOneSource(source, keyword)),
    );

    _isLoading = false;
    _statusMessage = _searchResults.isEmpty
        ? '未找到结果'
        : '找到 ${_searchResults.values.fold(0, (s, l) => s + l.length)} 本书';
    notifyListeners();
  }

  Future<void> _searchOneSource(BookSource source, String keyword) async {
    try {
      debugPrint(
        '  ▶ 书源: ${source.bookSourceName} (${source.bookSourceUrl})',
      );
      final results = await _sourceService
          .search(source, keyword)
          .timeout(const Duration(seconds: 20), onTimeout: () {
        debugPrint('  ⚠ ${source.bookSourceName}: 搜索超时 (20s)');
        return <Map<String, String>>[];
      });
      debugPrint('  ✓ ${source.bookSourceName}: ${results.length} 个结果');
      if (results.isEmpty) {
        debugPrint('  ⚠ ${source.bookSourceName}: 搜索返回 0 结果（书源规则或网络问题）');
      }
      if (results.isNotEmpty) {
        _searchResults[source.bookSourceUrl] = _sourceService.resultsToBooks(
          results,
          source.bookSourceUrl,
        );
        notifyListeners();
      }
    } catch (e, stack) {
      debugPrint('  ✗ ${source.bookSourceName}: 出错 — $e');
      debugPrint('     $stack');
    }
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
