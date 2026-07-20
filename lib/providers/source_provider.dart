import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../models/book.dart';
import '../models/book_source.dart';
import '../models/source_validation_result.dart';
import '../bridge/legado_engine_bridge.dart';
import '../database/dao/source_dao.dart';
import '../services/book_source_service.dart';
import '../services/source_group_catalog.dart';
import 'source_order.dart';

/// 书源管理 Provider — 书源 CRUD、搜索
class SourceProvider extends ChangeNotifier {
  final SourceDao _dao = SourceDao();
  final BookSourceService _sourceService = BookSourceService();

  List<BookSource> _sources = [];
  Map<String, List<Book>> _searchResults = {};
  final Map<String, SourceValidationResult> _validationResults = {};
  bool _isLoading = false;
  bool _isValidating = false;
  String _statusMessage = '';
  String? _validatingSourceUrl;
  String? _loadError;

  List<BookSource> get sources => _sources;
  Map<String, List<Book>> get searchResults => _searchResults;
  Map<String, SourceValidationResult> get validationResults =>
      Map.unmodifiable(_validationResults);
  bool get isLoading => _isLoading;
  bool get isValidating => _isValidating;
  String? get validatingSourceUrl => _validatingSourceUrl;
  String get statusMessage => _statusMessage;
  String? get loadError => _loadError;

  SourceValidationResult? validationOf(String sourceUrl) =>
      _validationResults[sourceUrl];

  /// 分组筛选/管理用：目录 ∪ 书源已有分组（不强制改书源）
  List<String> get knownGroups {
    final set = SourceGroupCatalog.names.toSet();
    for (final s in _sources) {
      final g = s.bookSourceGroup.trim();
      if (g.isNotEmpty) set.add(g);
    }
    return set.toList()..sort();
  }

  /// 加载书源
  Future<void> loadSources() async {
    _isLoading = true;
    _loadError = null;
    notifyListeners();
    try {
      await SourceGroupCatalog.load();
      _sources = await _dao.getAll();
      await SourceGroupCatalog.mergeFromSources(
        _sources.map((s) => s.bookSourceGroup),
      );
      _loadError = null;
    } catch (e) {
      _loadError = '加载书源失败: $e';
      debugPrint(_loadError);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 添加单个书源
  Future<void> addSource(BookSource source) async {
    await _dao.upsert(source);
    _sources = await _dao.getAll();
    notifyListeners();
  }

  /// 重命名分组（目录 + 所有该分组书源）
  Future<void> renameGroup(String oldName, String newName) async {
    if (oldName == newName) return;
    await SourceGroupCatalog.rename(oldName, newName);
    for (final s in _sources) {
      if (s.bookSourceGroup.trim() == oldName) {
        await _dao.update(s.copyWith(bookSourceGroup: newName));
      }
    }
    _sources = await _dao.getAll();
    notifyListeners();
  }

  /// 添加分组名到目录，**不**改动任何书源（避免未分组源被批量改写）。
  Future<bool> addGroup(String group) async {
    final name = group.trim();
    if (name.isEmpty) return false;
    final added = await SourceGroupCatalog.add(name);
    if (added) notifyListeners();
    return added;
  }

  /// 删除分组（目录移除；该书源 group 清空）
  Future<void> deleteGroup(String groupName) async {
    await SourceGroupCatalog.remove(groupName);
    for (final s in _sources) {
      if (s.bookSourceGroup.trim() == groupName) {
        await _dao.update(s.copyWith(bookSourceGroup: ''));
      }
    }
    _sources = await _dao.getAll();
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
      await _dao.upsertAll(sources);
      _sources = await _dao.getAll();
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
      await _dao.upsertAll(sources);
      _sources = await _dao.getAll();
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
    await _dao.toggle(sourceUrl, enabled);
    _sources = await _dao.getAll();
    notifyListeners();
  }

  /// 删除书源
  Future<void> deleteSource(String sourceUrl) async {
    await _dao.delete(sourceUrl);
    _validationResults.remove(sourceUrl);
    _sources = await _dao.getAll();
    notifyListeners();
  }

  /// 批量启用/禁用
  Future<void> setSourcesEnabled(
    Iterable<String> sourceUrls,
    bool enabled,
  ) async {
    final urls = sourceUrls.toSet();
    if (urls.isEmpty) return;
    for (final url in urls) {
      await _dao.toggle(url, enabled);
    }
    _sources = await _dao.getAll();
    notifyListeners();
  }

  /// 批量删除
  Future<void> deleteSources(Iterable<String> sourceUrls) async {
    final urls = sourceUrls.toSet();
    if (urls.isEmpty) return;
    for (final url in urls) {
      await _dao.delete(url);
      _validationResults.remove(url);
    }
    _sources = await _dao.getAll();
    notifyListeners();
  }

  /// 批量设置分组
  Future<void> setSourcesGroup(
    Iterable<String> sourceUrls,
    String group,
  ) async {
    await addGroupToSources(sourceUrls, group);
  }

  /// 批量启用/禁用发现
  Future<void> setSourcesExploreEnabled(
    Iterable<String> urls,
    bool enabled,
  ) async {
    final urlSet = urls.toSet();
    if (urlSet.isEmpty) return;
    for (final s in _sources) {
      if (!urlSet.contains(s.bookSourceUrl)) continue;
      await _dao.update(s.copyWith(enabledExplore: enabled));
    }
    _sources = await _dao.getAll();
    notifyListeners();
  }

  /// 将选中书源移到列表顶部
  Future<void> moveSourcesToTop(Iterable<String> urls) async {
    final selected = urls.toSet();
    if (selected.isEmpty) return;
    final orders = customOrdersAfterMoveToTop(
      sourcesInManualOrder(_sources),
      selected,
    );
    await _applyCustomOrders(orders);
  }

  /// 将选中书源移到列表底部
  Future<void> moveSourcesToBottom(Iterable<String> urls) async {
    final selected = urls.toSet();
    if (selected.isEmpty) return;
    final orders = customOrdersAfterMoveToBottom(
      sourcesInManualOrder(_sources),
      selected,
    );
    await _applyCustomOrders(orders);
  }

  /// 按给定 URL 顺序重排书源
  Future<void> reorderSources(List<String> orderedUrls) async {
    if (orderedUrls.isEmpty) return;
    final orders = {
      for (var i = 0; i < orderedUrls.length; i++) orderedUrls[i]: i,
    };
    await _applyCustomOrders(orders);
  }

  /// 导出选中书源为 JSON 数组
  Future<String> exportSourcesJson(Iterable<String> urls) async {
    final urlSet = urls.toSet();
    final list = _sources
        .where((s) => urlSet.contains(s.bookSourceUrl))
        .map((s) => s.toJson())
        .toList();
    return jsonEncode(list);
  }

  /// 为选中书源设置分组
  Future<void> addGroupToSources(Iterable<String> urls, String group) async {
    final urlSet = urls.toSet();
    if (urlSet.isEmpty) return;
    for (final s in _sources) {
      if (!urlSet.contains(s.bookSourceUrl)) continue;
      await _dao.update(s.copyWith(bookSourceGroup: group));
    }
    _sources = await _dao.getAll();
    await SourceGroupCatalog.mergeFromSources([group]);
    notifyListeners();
  }

  /// 清除选中书源的分组
  Future<void> clearGroupOnSources(Iterable<String> urls) async {
    final urlSet = urls.toSet();
    if (urlSet.isEmpty) return;
    for (final s in _sources) {
      if (!urlSet.contains(s.bookSourceUrl)) continue;
      await _dao.update(s.copyWith(bookSourceGroup: ''));
    }
    _sources = await _dao.getAll();
    notifyListeners();
  }

  Future<void> _applyCustomOrders(Map<String, int> orders) async {
    if (orders.isEmpty) return;
    for (final s in _sources) {
      final order = orders[s.bookSourceUrl];
      if (order == null || order == s.customOrder) continue;
      await _dao.update(s.copyWith(customOrder: order));
    }
    _sources = await _dao.getAll();
    notifyListeners();
  }

  /// 更新单个书源
  Future<void> updateSource(BookSource source) async {
    await _dao.update(source);
    _sources = await _dao.getAll();
    notifyListeners();
  }

  // ── 搜索 ──

  /// 联合搜索已启用书源（可限定范围 / 作者筛选）
  ///
  /// [restrictSourceUrls] 非空时只搜这些书源；为空则全部已启用书源。
  /// [author] 非空时对结果做作者包含过滤。
  /// [preciseName] 为 true 时结果书名须包含 [keyword]。
  Future<void> searchAll(
    String keyword, {
    String? author,
    bool preciseName = false,
    Set<String>? restrictSourceUrls,
  }) async {
    if (keyword.isEmpty) return;
    _isLoading = true;
    _searchResults = {};
    _statusMessage = '正在搜索 "$keyword"...';
    notifyListeners();

    var enabledSources = await _dao.getEnabled();
    if (restrictSourceUrls != null && restrictSourceUrls.isNotEmpty) {
      enabledSources = enabledSources
          .where((s) => restrictSourceUrls.contains(s.bookSourceUrl))
          .toList();
    }
    debugPrint('📡 搜索 "$keyword"，共 ${enabledSources.length} 个书源');

    if (enabledSources.isEmpty) {
      _isLoading = false;
      _statusMessage = restrictSourceUrls != null && restrictSourceUrls.isNotEmpty
          ? '所选范围内没有启用的书源'
          : '没有启用的书源，请先导入书源';
      notifyListeners();
      return;
    }

    await Future.wait(
      enabledSources.map(
        (source) => _searchOneSource(
          source,
          keyword,
          author: author,
          preciseName: preciseName,
        ),
      ),
    );

    _isLoading = false;
    _statusMessage = _searchResults.isEmpty
        ? '未找到结果'
        : '找到 ${_searchResults.values.fold(0, (s, l) => s + l.length)} 本书';
    notifyListeners();
  }

  Future<void> _searchOneSource(
    BookSource source,
    String keyword, {
    String? author,
    bool preciseName = false,
  }) async {
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
        var books = _sourceService.resultsToBooks(
          results,
          source.bookSourceUrl,
        );
        final a = author?.trim() ?? '';
        if (a.isNotEmpty) {
          books = books
              .where((b) => b.author.toLowerCase().contains(a.toLowerCase()))
              .toList();
        }
        if (preciseName) {
          final k = keyword.toLowerCase();
          books = books
              .where((b) => b.name.toLowerCase().contains(k))
              .toList();
        }
        if (books.isEmpty) return;
        _searchResults[source.bookSourceUrl] = books;
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

  /// 校验单个书源（搜索 → 发现 → 目录 → 正文）
  Future<SourceValidationResult?> validateSource(
    BookSource source, {
    String? keyword,
  }) async {
    if (!LegadoEngineBridge.isAvailable) {
      _statusMessage = 'Rust 引擎不可用，无法校验';
      notifyListeners();
      return null;
    }

    final key = defaultValidationKeyword(
      source.bookSourceName,
      source.bookSourceUrl,
    );
    final query = (keyword?.trim().isNotEmpty == true) ? keyword!.trim() : key;

    _isValidating = true;
    _validatingSourceUrl = source.bookSourceUrl;
    notifyListeners();

    try {
      final raw = await LegadoEngineBridge.validateSource(
        source,
        keyword: query,
      );
      final result = SourceValidationResult.fromRust(raw);
      _validationResults[source.bookSourceUrl] = result;
      _statusMessage = result.allOk
          ? '${source.bookSourceName} 校验通过'
          : '${source.bookSourceName} 校验未完全通过';
      return result;
    } catch (e) {
      debugPrint('  ✗ 校验失败 ${source.bookSourceName}: $e');
      _statusMessage = '校验失败: $e';
      return null;
    } finally {
      _isValidating = false;
      _validatingSourceUrl = null;
      notifyListeners();
    }
  }

  /// 批量校验已启用书源
  Future<int> validateEnabledSources({void Function(int done, int total)? onProgress}) async {
    final enabled = _sources.where((s) => s.enabled).toList();
    return validateSources(enabled, onProgress: onProgress);
  }

  /// 批量校验指定书源
  Future<int> validateSources(
    List<BookSource> sources, {
    void Function(int done, int total)? onProgress,
  }) async {
    if (sources.isEmpty) return 0;
    var passed = 0;
    for (var i = 0; i < sources.length; i++) {
      onProgress?.call(i, sources.length);
      final result = await validateSource(sources[i]);
      if (result?.pipelineOk == true) passed++;
    }
    onProgress?.call(sources.length, sources.length);
    _statusMessage = '批量校验完成：$passed/${sources.length} 可用';
    notifyListeners();
    return passed;
  }
}
