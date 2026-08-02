import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../domain/book/book.dart';
import '../../domain/ports/book_source_validation_port.dart';
import '../../domain/repositories/book_source_repository.dart';
import '../../domain/source/book_source.dart';
import '../../domain/source/source_validation_result.dart';
import '../source_login/source_login_page_port.dart';
import '../source_rules/check_source_prefs_port.dart';
import '../source_validation/source_validation_policy.dart';
import '../source_validation/source_validation_store_port.dart';
import 'source_group_catalog_port.dart';
import 'source_management_book_source_port.dart';
import 'source_state.dart';

Future<List<BookSource>> _emptyBuiltInSources() async => const [];

typedef SourceStateListener = void Function(SourceState state);

/// 书源管理的 application 控制器。
///
/// 旧 ChangeNotifier 兼容外观和 Riverpod Notifier 共同监听这个控制器，
/// 因而书源、搜索结果和校验结果始终只有一份共享状态。
final class SourceController {
  SourceController({
    required BookSourceRepository repository,
    required BookSourceValidationPort validationPort,
    required SourceManagementBookSourcePort sourceService,
    SourceLoginPagePort? loginPort,
    CheckSourcePrefsPort? checkSourcePrefsPort,
    SourceGroupCatalogPort? sourceGroupPort,
    SourceValidationStorePort? validationStorePort,
    Future<List<BookSource>> Function()? builtInSourcesLoader,
  }) : _repository = repository,
       _validationPort = validationPort,
       _sourceService = sourceService,
       _loginPort = loginPort ?? const UnavailableSourceLoginPagePort(),
       _checkSourcePrefs =
           checkSourcePrefsPort ?? const UnavailableCheckSourcePrefsPort(),
       _sourceGroupPort =
           sourceGroupPort ?? const UnavailableSourceGroupCatalogPort(),
       _validationStorePort =
           validationStorePort ?? const UnavailableSourceValidationStorePort(),
       _builtInSourcesLoader = builtInSourcesLoader ?? _emptyBuiltInSources;

  final BookSourceRepository _repository;
  final BookSourceValidationPort _validationPort;
  final SourceManagementBookSourcePort _sourceService;
  final SourceLoginPagePort _loginPort;
  final CheckSourcePrefsPort _checkSourcePrefs;
  final SourceGroupCatalogPort _sourceGroupPort;
  final SourceValidationStorePort _validationStorePort;
  final Future<List<BookSource>> Function() _builtInSourcesLoader;
  final Set<SourceStateListener> _listeners = {};

  SourceState _state = const SourceState();
  int _loadRequest = 0;
  int _searchRequest = 0;
  int _validationRequest = 0;
  int _importRequest = 0;
  bool _loadActive = false;
  bool _searchActive = false;
  bool _importActive = false;
  int? _validationActiveRequest;
  Future<void>? _ensureBuiltInsInFlight;

  SourceState get state => _state;
  BookSourceRepository get repository => _repository;
  List<BookSource> get sources => _state.sources;
  Map<String, List<Book>> get searchResults => _state.searchResults;
  Map<String, SourceValidationResult> get validationResults =>
      _state.validationResults;
  Map<String, String> get validationProgress => _state.validationProgress;
  bool get isLoading => _state.isLoading;
  bool get isValidating => _state.isValidating;
  String? get validatingSourceUrl => _state.validatingSourceUrl;
  String get statusMessage => _state.statusMessage;
  String? get loadError => _state.loadError;

  void addListener(SourceStateListener listener) => _listeners.add(listener);

  void removeListener(SourceStateListener listener) =>
      _listeners.remove(listener);

  SourceValidationResult? validationOf(String sourceUrl) =>
      _state.validationResults[sourceUrl];

  String? validationProgressOf(String sourceUrl) =>
      _state.validationProgress[sourceUrl];

  /// 分组筛选/管理用：目录 ∪ 书源已有分组标签（不强制改书源）。
  List<String> get knownGroups {
    final set = _sourceGroupPort.names.toSet();
    for (final source in _state.sources) {
      for (final tag in _sourceGroupPort.splitGroups(source.bookSourceGroup)) {
        set.add(tag);
      }
    }
    return set.toList()..sort();
  }

  /// 加载书源；较早的加载请求不能覆盖较晚请求的结果。
  Future<void> loadSources() async {
    final request = ++_loadRequest;
    _loadActive = true;
    _emit(isLoading: true, loadError: null);
    try {
      await _sourceGroupPort.load();
      final loadedSources = await _repository.getAll();
      await _sourceGroupPort.mergeFromSources(
        loadedSources.map((source) => source.bookSourceGroup),
      );
      final validationResults = await _validationStorePort.load();
      if (!_isCurrentLoad(request)) return;
      _loadActive = false;
      _emit(
        sources: loadedSources,
        validationResults: validationResults,
        isLoading: _anyLoading,
        loadError: null,
      );
    } catch (error) {
      if (!_isCurrentLoad(request)) return;
      final message = '加载书源失败: $error';
      debugPrint(message);
      _loadActive = false;
      _emit(isLoading: _anyLoading, loadError: message);
    } finally {
      if (_isCurrentLoad(request)) {
        _loadActive = false;
        _emit(isLoading: _anyLoading);
      }
    }
  }

  /// 确保首次启动时只在空仓库中导入内置书源。
  Future<void> ensureBuiltInSources() {
    final inFlight = _ensureBuiltInsInFlight;
    if (inFlight != null) return inFlight;
    late Future<void> future;
    future = _ensureBuiltInSources();
    _ensureBuiltInsInFlight = future;
    return future.whenComplete(() {
      if (identical(_ensureBuiltInsInFlight, future)) {
        _ensureBuiltInsInFlight = null;
      }
    });
  }

  Future<void> _ensureBuiltInSources() async {
    if ((await _repository.getAll()).isNotEmpty) return;
    final builtIns = await _builtInSourcesLoader();
    if (builtIns.isEmpty) return;
    _invalidateLoadRequest();
    await _repository.upsertAll(builtIns);
  }

  /// 添加单个书源。
  Future<void> addSource(BookSource source) async {
    _invalidateLoadRequest();
    await _repository.upsert(source);
    await _reloadSources();
  }

  /// 重命名分组（目录 + 所有含该标签的书源）。
  Future<void> renameGroup(String oldName, String newName) async {
    if (oldName == newName) return;
    _invalidateLoadRequest();
    await _sourceGroupPort.rename(oldName, newName);
    for (final source in _state.sources) {
      if (!_sourceGroupPort.hasGroupTag(source.bookSourceGroup, oldName)) {
        continue;
      }
      await _repository.update(
        source.copyWith(
          bookSourceGroup: _sourceGroupPort.renameGroupTag(
            source.bookSourceGroup,
            oldName,
            newName,
          ),
        ),
      );
    }
    await _reloadSources();
  }

  /// 添加分组名到目录，不改动任何书源。
  Future<bool> addGroup(String group) async {
    final name = group.trim();
    if (name.isEmpty) return false;
    _invalidateLoadRequest();
    final added = await _sourceGroupPort.add(name);
    if (added) _emit();
    return added;
  }

  /// 删除分组（目录移除；从各书源去掉该标签，其它标签保留）。
  Future<void> deleteGroup(String groupName) async {
    _invalidateLoadRequest();
    await _sourceGroupPort.remove(groupName);
    for (final source in _state.sources) {
      if (!_sourceGroupPort.hasGroupTag(source.bookSourceGroup, groupName)) {
        continue;
      }
      await _repository.update(
        source.copyWith(
          bookSourceGroup: _sourceGroupPort.removeGroupTag(
            source.bookSourceGroup,
            groupName,
          ),
        ),
      );
    }
    await _reloadSources();
  }

  /// 解析导入文本为书源列表（不写库；URL 则先拉网）。
  Future<List<BookSource>?> parseSourcesForImport(String text) async {
    final normalized = _normalizeImportText(text);
    if (normalized.isEmpty) return null;

    if (_looksLikeUrl(normalized)) {
      try {
        final sources = await _sourceService.fetchSourcesFromUrl(normalized);
        return sources.isEmpty ? null : sources;
      } catch (error) {
        debugPrint('  ✗ 从 URL 解析书源失败: $error');
        return null;
      }
    }

    try {
      final decoded = jsonDecode(normalized);
      final list = extractSourceListFromDecoded(decoded);
      if (list == null || list.isEmpty) return null;
      final sources = list
          .whereType<Map<String, dynamic>>()
          .map(BookSource.fromJson)
          .toList();
      return sources.isEmpty ? null : sources;
    } catch (error) {
      debugPrint('  ✗ JSON 解析失败: $error');
      return null;
    }
  }

  /// 写入已解析的书源（仅 upsert 传入列表）。
  Future<bool> importParsedSources(List<BookSource> sources) async {
    if (sources.isEmpty) return false;
    _invalidateLoadRequest();
    await _repository.upsertAll(sources);
    await _reloadSources();
    _emit(statusMessage: '已导入 ${sources.length} 个书源');
    return true;
  }

  /// 从 JSON 文本或书源订阅 URL 导入。
  Future<bool> importSources(String jsonText) async {
    final text = _normalizeImportText(jsonText);
    if (text.isEmpty) return false;

    if (_looksLikeUrl(text)) {
      debugPrint('  ▸ 检测到书源 URL，自动拉取: $text');
      return importSourcesFromUrl(text);
    }

    final request = ++_importRequest;
    _importActive = true;
    _emit(isLoading: true);
    try {
      final sources = await parseSourcesForImport(text);
      if (!_isCurrentImport(request)) return false;
      if (sources == null || sources.isEmpty) {
        _emit(statusMessage: '未找到有效书源数据');
        return false;
      }
      return await importParsedSources(sources);
    } catch (error) {
      if (_isCurrentImport(request)) {
        debugPrint('  ✗ JSON 解析失败: $error');
        _emit(statusMessage: 'JSON 解析失败，请检查格式或改用「从URL导入」');
      }
      return false;
    } finally {
      if (_isCurrentImport(request)) {
        _importActive = false;
        _emit(isLoading: _anyLoading);
      }
    }
  }

  static String _normalizeImportText(String raw) {
    var text = raw.trim().replaceFirst('\uFEFF', '');
    final firstLine = text.split(RegExp(r'\r?\n')).first.trim();
    if (_looksLikeUrl(firstLine)) return firstLine;
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

  /// 从已解码 JSON 提取书源数组，供导入预览与测试使用。
  static List<dynamic>? extractSourceListFromDecoded(dynamic decoded) {
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
        final value = decoded[key];
        if (value is List) return value;
      }
    }
    return null;
  }

  /// 从 URL 导入。
  Future<bool> importSourcesFromUrl(String url) async {
    final request = ++_importRequest;
    _importActive = true;
    _emit(isLoading: true);
    try {
      final sources = await parseSourcesForImport(url);
      if (!_isCurrentImport(request)) return false;
      if (sources == null || sources.isEmpty) {
        _emit(statusMessage: 'URL 未返回有效书源，请检查链接或网络');
        return false;
      }
      final imported = await importParsedSources(sources);
      if (_isCurrentImport(request)) {
        _emit(statusMessage: '已从 URL 导入 ${sources.length} 个书源');
      }
      return imported;
    } catch (error) {
      if (_isCurrentImport(request)) {
        debugPrint('  ✗ 从 URL 导入失败: $error');
        _emit(statusMessage: '从 URL 获取书源失败: $error');
      }
      return false;
    } finally {
      if (_isCurrentImport(request)) {
        _importActive = false;
        _emit(isLoading: _anyLoading);
      }
    }
  }

  /// 启用/禁用书源。
  Future<void> toggleSource(String sourceUrl, bool enabled) async {
    _invalidateLoadRequest();
    await _repository.toggle(sourceUrl, enabled);
    await _reloadSources();
  }

  /// 删除书源。
  Future<void> deleteSource(String sourceUrl) async {
    _invalidateLoadRequest();
    _invalidateValidationRequest();
    await _repository.delete(sourceUrl);
    await _validationStorePort.remove(sourceUrl);
    final nextResults = Map<String, SourceValidationResult>.of(
      _state.validationResults,
    )..remove(sourceUrl);
    await _reloadSources();
    _emit(validationResults: nextResults);
  }

  /// 批量启用/禁用。
  Future<void> setSourcesEnabled(
    Iterable<String> sourceUrls,
    bool enabled,
  ) async {
    final urls = sourceUrls.toSet();
    if (urls.isEmpty) return;
    _invalidateLoadRequest();
    for (final url in urls) {
      await _repository.toggle(url, enabled);
    }
    await _reloadSources();
  }

  /// 批量删除。
  Future<void> deleteSources(Iterable<String> sourceUrls) async {
    final urls = sourceUrls.toSet();
    if (urls.isEmpty) return;
    _invalidateLoadRequest();
    _invalidateValidationRequest();
    for (final url in urls) {
      await _repository.delete(url);
      await _validationStorePort.remove(url);
    }
    final nextResults = Map<String, SourceValidationResult>.of(
      _state.validationResults,
    )..removeWhere((url, _) => urls.contains(url));
    await _reloadSources();
    _emit(validationResults: nextResults);
  }

  /// 批量设置分组。
  Future<void> setSourcesGroup(Iterable<String> sourceUrls, String group) =>
      addGroupToSources(sourceUrls, group);

  /// 批量启用/禁用发现。
  Future<void> setSourcesExploreEnabled(
    Iterable<String> urls,
    bool enabled,
  ) async {
    final urlSet = urls.toSet();
    if (urlSet.isEmpty) return;
    _invalidateLoadRequest();
    for (final source in _state.sources) {
      if (!urlSet.contains(source.bookSourceUrl)) continue;
      await _repository.update(source.copyWith(enabledExplore: enabled));
    }
    await _reloadSources();
  }

  /// 将选中书源移到列表顶部。
  Future<void> moveSourcesToTop(Iterable<String> urls) async {
    final selected = urls.toSet();
    if (selected.isEmpty) return;
    await _applyCustomOrders(
      _customOrdersAfterMoveToTop(
        _sourcesInManualOrder(_state.sources),
        selected,
      ),
    );
  }

  /// 将选中书源移到列表底部。
  Future<void> moveSourcesToBottom(Iterable<String> urls) async {
    final selected = urls.toSet();
    if (selected.isEmpty) return;
    await _applyCustomOrders(
      _customOrdersAfterMoveToBottom(
        _sourcesInManualOrder(_state.sources),
        selected,
      ),
    );
  }

  /// 按给定 URL 顺序重排书源。
  Future<void> reorderSources(List<String> orderedUrls) async {
    if (orderedUrls.isEmpty) return;
    await _applyCustomOrders({
      for (var i = 0; i < orderedUrls.length; i++) orderedUrls[i]: i,
    });
  }

  /// 导出选中书源为 JSON 数组。
  Future<String> exportSourcesJson(Iterable<String> urls) async {
    final urlSet = urls.toSet();
    final list = _state.sources
        .where((source) => urlSet.contains(source.bookSourceUrl))
        .map((source) => source.toJson())
        .toList();
    return jsonEncode(list);
  }

  /// 为选中书源追加分组标签，保留已有标签。
  Future<void> addGroupToSources(Iterable<String> urls, String group) async {
    final urlSet = urls.toSet();
    final tag = group.trim();
    if (urlSet.isEmpty || tag.isEmpty) return;
    _invalidateLoadRequest();
    for (final source in _state.sources) {
      if (!urlSet.contains(source.bookSourceUrl)) continue;
      final next = _sourceGroupPort.addGroupTag(source.bookSourceGroup, tag);
      if (next == source.bookSourceGroup) continue;
      await _repository.update(source.copyWith(bookSourceGroup: next));
    }
    await _reloadSources();
    await _sourceGroupPort.mergeFromSources([tag]);
    _emit();
  }

  /// 清除选中书源的全部分组标签。
  Future<void> clearGroupOnSources(Iterable<String> urls) async {
    final urlSet = urls.toSet();
    if (urlSet.isEmpty) return;
    _invalidateLoadRequest();
    for (final source in _state.sources) {
      if (!urlSet.contains(source.bookSourceUrl) ||
          source.bookSourceGroup.isEmpty) {
        continue;
      }
      await _repository.update(source.copyWith(bookSourceGroup: ''));
    }
    await _reloadSources();
  }

  /// 从选中书源移除单个分组标签，其它标签保留。
  Future<void> removeGroupTagFromSources(
    Iterable<String> urls,
    String tag,
  ) async {
    final urlSet = urls.toSet();
    final trimmed = tag.trim();
    if (urlSet.isEmpty || trimmed.isEmpty) return;
    _invalidateLoadRequest();
    for (final source in _state.sources) {
      if (!urlSet.contains(source.bookSourceUrl) ||
          !_sourceGroupPort.hasGroupTag(source.bookSourceGroup, trimmed)) {
        continue;
      }
      await _repository.update(
        source.copyWith(
          bookSourceGroup: _sourceGroupPort.removeGroupTag(
            source.bookSourceGroup,
            trimmed,
          ),
        ),
      );
    }
    await _reloadSources();
  }

  Future<void> _applyCustomOrders(Map<String, int> orders) async {
    if (orders.isEmpty) return;
    _invalidateLoadRequest();
    for (final source in _state.sources) {
      final order = orders[source.bookSourceUrl];
      if (order == null || order == source.customOrder) continue;
      await _repository.update(source.copyWith(customOrder: order));
    }
    await _reloadSources();
  }

  /// 更新单个书源。
  Future<void> updateSource(BookSource source) async {
    _invalidateLoadRequest();
    await _repository.update(source);
    await _reloadSources();
  }

  // ── 搜索 ──

  /// 联合搜索已启用书源，可限定范围并过滤作者或书名。
  Future<void> searchAll(
    String keyword, {
    String? author,
    bool preciseName = false,
    Set<String>? restrictSourceUrls,
  }) async {
    if (keyword.isEmpty) return;
    final request = ++_searchRequest;
    _searchActive = true;
    _emit(
      isLoading: true,
      searchResults: const {},
      statusMessage: '正在搜索 "$keyword"...',
    );

    try {
      var enabledSources = await _repository.getEnabled();
      if (!_isCurrentSearch(request)) return;
      if (restrictSourceUrls != null && restrictSourceUrls.isNotEmpty) {
        enabledSources = enabledSources
            .where(
              (source) => restrictSourceUrls.contains(source.bookSourceUrl),
            )
            .toList();
      }
      debugPrint('📡 搜索 "$keyword"，共 ${enabledSources.length} 个书源');

      if (enabledSources.isEmpty) {
        final message =
            restrictSourceUrls != null && restrictSourceUrls.isNotEmpty
            ? '所选范围内没有启用的书源'
            : '没有启用的书源，请先导入书源';
        _emit(statusMessage: message);
        return;
      }

      await Future.wait(
        enabledSources.map(
          (source) => _searchOneSource(
            source,
            keyword,
            request: request,
            author: author,
            preciseName: preciseName,
          ),
        ),
      );
      if (!_isCurrentSearch(request)) return;
      final count = _state.searchResults.values.fold<int>(
        0,
        (sum, books) => sum + books.length,
      );
      _emit(statusMessage: count == 0 ? '未找到结果' : '找到 $count 本书');
    } catch (error, stack) {
      if (_isCurrentSearch(request)) {
        debugPrint('  ✗ 联合搜索失败: $error');
        debugPrint('     $stack');
        _emit(statusMessage: '搜索失败: $error');
      }
    } finally {
      if (_isCurrentSearch(request)) {
        _searchActive = false;
        _emit(isLoading: _anyLoading);
      }
    }
  }

  Future<void> _searchOneSource(
    BookSource source,
    String keyword, {
    required int request,
    String? author,
    bool preciseName = false,
  }) async {
    try {
      debugPrint('  ▶ 书源: ${source.bookSourceName} (${source.bookSourceUrl})');
      final results = await _sourceService
          .search(source, keyword)
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              debugPrint('  ⚠ ${source.bookSourceName}: 搜索超时 (20s)');
              return <Map<String, String>>[];
            },
          );
      if (!_isCurrentSearch(request)) return;
      debugPrint('  ✓ ${source.bookSourceName}: ${results.length} 个结果');
      if (results.isEmpty) {
        debugPrint('  ⚠ ${source.bookSourceName}: 搜索返回 0 结果（书源规则或网络问题）');
      }
      if (results.isEmpty) return;
      var books = _sourceService.resultsToBooks(results, source.bookSourceUrl);
      final authorFilter = author?.trim() ?? '';
      if (authorFilter.isNotEmpty) {
        books = books
            .where(
              (book) => book.author.toLowerCase().contains(
                authorFilter.toLowerCase(),
              ),
            )
            .toList();
      }
      if (preciseName) {
        final keywordLower = keyword.toLowerCase();
        books = books
            .where((book) => book.name.toLowerCase().contains(keywordLower))
            .toList();
      }
      if (books.isEmpty || !_isCurrentSearch(request)) return;
      final nextResults = Map<String, List<Book>>.of(_state.searchResults)
        ..[source.bookSourceUrl] = List<Book>.unmodifiable(books);
      _emit(searchResults: nextResults);
    } catch (error, stack) {
      debugPrint('  ✗ ${source.bookSourceName}: 出错 — $error');
      debugPrint('     $stack');
    }
  }

  /// 根据书籍查找对应书源（用于阅读）。
  BookSource? findSourceForBook(Book book) {
    if (book.bookSourceUrl.isNotEmpty) {
      for (final source in _state.sources) {
        if (source.bookSourceUrl == book.bookSourceUrl) return source;
      }
    }
    for (final source in _state.sources) {
      if (book.id.startsWith(source.bookSourceUrl)) return source;
    }
    for (final source in _state.sources) {
      if (book.sourceUrl.startsWith(source.bookSourceUrl)) return source;
    }
    return null;
  }

  /// 返回书籍资源图片所用请求头，登录头覆盖同名书源请求头。
  Future<Map<String, String>> imageHeadersForSource(BookSource source) async {
    final headers = <String, String>{...source.customHeaders};
    final loginHeader = await _loginPort.loadHeader(source.bookSourceUrl);
    headers.addAll(_loginPort.parseLoginHeader(loginHeader ?? ''));
    return Map.unmodifiable(headers);
  }

  Future<Map<String, String>> imageHeadersForBook(Book book) async {
    final source = findSourceForBook(book);
    if (source == null) return const {};
    return imageHeadersForSource(source);
  }

  /// 校验单个书源（搜索 → 发现 → 目录 → 正文）。
  Future<SourceValidationResult?> validateSource(
    BookSource source, {
    String? keyword,
  }) {
    final request = ++_validationRequest;
    return _validateSource(source, request: request, keyword: keyword);
  }

  Future<SourceValidationResult?> _validateSource(
    BookSource source, {
    required int request,
    String? keyword,
  }) async {
    if (!_validationPort.isAvailable) {
      if (_isCurrentValidationRequest(request)) {
        _validationActiveRequest = null;
        _emit(
          isValidating: false,
          validatingSourceUrl: null,
          validationProgress: const {},
          statusMessage: 'Rust 引擎不可用，无法校验',
        );
      }
      return null;
    }

    _validationActiveRequest = request;
    _emit(
      isValidating: true,
      validatingSourceUrl: source.bookSourceUrl,
      validationProgress: const {},
    );

    Timer? stageTimer;
    try {
      final fallback = defaultValidationKeyword(
        source.bookSourceName,
        source.bookSourceUrl,
      );
      final String query;
      if (keyword?.trim().isNotEmpty == true) {
        query = keyword!.trim();
        await _checkSourcePrefs.setLastKeyword(query);
      } else {
        final lastKeyword = await _checkSourcePrefs.lastKeyword();
        query = lastKeyword.isNotEmpty ? lastKeyword : fallback;
      }

      final timeoutSec = await _checkSourcePrefs.timeoutSec();
      final checkSearch = await _checkSourcePrefs.checkSearch();
      final checkDiscovery = await _checkSourcePrefs.checkDiscovery();
      final checkToc = await _checkSourcePrefs.checkToc();
      final checkContent = await _checkSourcePrefs.checkContent();
      final stages = <String>[
        if (checkSearch) '搜索中…',
        if (checkDiscovery) '发现…',
        if (checkToc) '目录…',
        if (checkContent) '正文…',
      ];
      if (stages.isEmpty) stages.add('校验中…');
      if (!_isCurrentValidation(request)) return null;

      var stageIndex = 0;
      _emit(validationProgress: {source.bookSourceUrl: stages[stageIndex]});
      stageTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
        if (!_isCurrentValidation(request)) return;
        if (stageIndex >= stages.length - 1) return;
        stageIndex++;
        _emit(validationProgress: {source.bookSourceUrl: stages[stageIndex]});
      });

      final raw = await _validationPort
          .validateSource(source, keyword: query)
          .timeout(
            Duration(seconds: timeoutSec),
            onTimeout: () {
              throw TimeoutException('校验超时 (${timeoutSec}s)');
            },
          );
      if (!_isCurrentValidation(request)) return null;
      final result = _applyCheckPrefsToResult(
        SourceValidationResult(
          searchOk: raw.searchOk,
          discoveryOk: raw.discoveryOk,
          tocOk: raw.tocOk,
          contentOk: raw.contentOk,
          searchTimeMs: raw.searchTimeMs,
          errors: List<String>.from(raw.errors),
        ),
        checkSearch: checkSearch,
        checkDiscovery: checkDiscovery,
        checkToc: checkToc,
        checkContent: checkContent,
      );
      final nextResults = Map<String, SourceValidationResult>.of(
        _state.validationResults,
      )..[source.bookSourceUrl] = result;
      // Keep the successful in-memory result even when persistence fails.
      // This matches the legacy provider contract and lets the next load
      // reconcile persistence without discarding the completed validation.
      _emit(validationResults: nextResults);
      await _validationStorePort.put(source.bookSourceUrl, result);
      if (!_isCurrentValidation(request)) return null;

      _emit(
        validationProgress: {source.bookSourceUrl: '完成'},
        statusMessage: result.allOk
            ? '${source.bookSourceName} 校验通过'
            : '${source.bookSourceName} 校验未完全通过',
      );
      if (result.searchTimeMs > 0) {
        await _repository.update(
          source.copyWith(respondTime: result.searchTimeMs),
        );
        if (_isCurrentValidation(request)) {
          final refreshed = await _repository.getAll();
          if (_isCurrentValidation(request)) _emit(sources: refreshed);
        }
      }
      return result;
    } catch (error) {
      if (_isCurrentValidation(request)) {
        debugPrint('  ✗ 校验失败 ${source.bookSourceName}: $error');
        _emit(
          validationProgress: {source.bookSourceUrl: '失败: $error'},
          statusMessage: '校验失败: $error',
        );
      }
      return null;
    } finally {
      stageTimer?.cancel();
      if (_isCurrentValidation(request)) {
        _validationActiveRequest = null;
        _emit(
          validationProgress: const {},
          isValidating: false,
          validatingSourceUrl: null,
        );
      }
    }
  }

  /// 未勾选的校验项在持久化结果中视为通过。
  static SourceValidationResult _applyCheckPrefsToResult(
    SourceValidationResult result, {
    required bool checkSearch,
    required bool checkDiscovery,
    required bool checkToc,
    required bool checkContent,
  }) {
    return SourceValidationResult(
      searchOk: checkSearch ? result.searchOk : true,
      discoveryOk: checkDiscovery ? result.discoveryOk : true,
      tocOk: checkToc ? result.tocOk : true,
      contentOk: checkContent ? result.contentOk : true,
      searchTimeMs: result.searchTimeMs,
      errors: result.errors,
    );
  }

  /// 批量校验已启用书源。
  Future<int> validateEnabledSources({
    String? keyword,
    void Function(int done, int total)? onProgress,
  }) async {
    final enabled = _state.sources.where((source) => source.enabled).toList();
    return validateSources(enabled, keyword: keyword, onProgress: onProgress);
  }

  /// 批量校验指定书源；批量任务共用一个请求序号，便于整体失效。
  Future<int> validateSources(
    List<BookSource> sources, {
    String? keyword,
    void Function(int done, int total)? onProgress,
  }) async {
    if (sources.isEmpty) return 0;
    final request = ++_validationRequest;
    var passed = 0;
    for (var i = 0; i < sources.length; i++) {
      if (!_isCurrentValidationRequest(request)) break;
      onProgress?.call(i, sources.length);
      final result = await _validateSource(
        sources[i],
        request: request,
        keyword: keyword,
      );
      if (result?.pipelineOk == true) passed++;
    }
    if (!_isCurrentValidationRequest(request)) return passed;
    onProgress?.call(sources.length, sources.length);
    _emit(statusMessage: '批量校验完成：$passed/${sources.length} 可用');
    return passed;
  }

  void _invalidateLoadRequest() {
    _loadRequest++;
    final wasActive = _loadActive;
    _loadActive = false;
    if (wasActive || _state.isLoading != _anyLoading) {
      _emit(isLoading: _anyLoading);
    }
  }

  void _invalidateValidationRequest() {
    _validationRequest++;
    _validationActiveRequest = null;
    _emit(
      validationProgress: const {},
      isValidating: false,
      validatingSourceUrl: null,
    );
  }

  Future<void> _reloadSources() async {
    final loadedSources = await _repository.getAll();
    _emit(sources: loadedSources);
  }

  bool _isCurrentLoad(int request) => request == _loadRequest;

  bool _isCurrentSearch(int request) => request == _searchRequest;

  bool _isCurrentImport(int request) => request == _importRequest;

  bool _isCurrentValidationRequest(int request) =>
      request == _validationRequest;

  bool _isCurrentValidation(int request) =>
      request == _validationRequest && _validationActiveRequest == request;

  bool get _anyLoading => _loadActive || _searchActive || _importActive;

  static List<BookSource> _sourcesInManualOrder(List<BookSource> all) {
    final ordered = List<BookSource>.of(all)
      ..sort((left, right) {
        final byOrder = left.customOrder.compareTo(right.customOrder);
        if (byOrder != 0) return byOrder;
        return left.bookSourceUrl.compareTo(right.bookSourceUrl);
      });
    return ordered;
  }

  static Map<String, int> _customOrdersAfterMoveToTop(
    List<BookSource> all,
    Set<String> selected,
  ) {
    final chosen = all.where(
      (source) => selected.contains(source.bookSourceUrl),
    );
    final rest = all.where(
      (source) => !selected.contains(source.bookSourceUrl),
    );
    final ordered = [...chosen, ...rest];
    return {
      for (var i = 0; i < ordered.length; i++) ordered[i].bookSourceUrl: i,
    };
  }

  static Map<String, int> _customOrdersAfterMoveToBottom(
    List<BookSource> all,
    Set<String> selected,
  ) {
    final rest = all.where(
      (source) => !selected.contains(source.bookSourceUrl),
    );
    final chosen = all.where(
      (source) => selected.contains(source.bookSourceUrl),
    );
    final ordered = [...rest, ...chosen];
    return {
      for (var i = 0; i < ordered.length; i++) ordered[i].bookSourceUrl: i,
    };
  }

  static const Object _unset = Object();

  void _emit({
    List<BookSource>? sources,
    Map<String, List<Book>>? searchResults,
    Map<String, SourceValidationResult>? validationResults,
    Map<String, String>? validationProgress,
    bool? isLoading,
    bool? isValidating,
    Object? validatingSourceUrl = _unset,
    String? statusMessage,
    Object? loadError = _unset,
  }) {
    final previous = _state;
    _state = SourceState(
      sources: List<BookSource>.unmodifiable(sources ?? previous.sources),
      searchResults: _freezeSearchResults(
        searchResults ?? previous.searchResults,
      ),
      validationResults: Map<String, SourceValidationResult>.unmodifiable(
        validationResults ?? previous.validationResults,
      ),
      validationProgress: Map<String, String>.unmodifiable(
        validationProgress ?? previous.validationProgress,
      ),
      isLoading: isLoading ?? previous.isLoading,
      isValidating: isValidating ?? previous.isValidating,
      validatingSourceUrl: identical(validatingSourceUrl, _unset)
          ? previous.validatingSourceUrl
          : validatingSourceUrl as String?,
      statusMessage: statusMessage ?? previous.statusMessage,
      loadError: identical(loadError, _unset)
          ? previous.loadError
          : loadError as String?,
    );
    for (final listener in List<SourceStateListener>.of(_listeners)) {
      listener(_state);
    }
  }

  static Map<String, List<Book>> _freezeSearchResults(
    Map<String, List<Book>> results,
  ) => Map<String, List<Book>>.unmodifiable({
    for (final entry in results.entries)
      entry.key: List<Book>.unmodifiable(entry.value),
  });
}
