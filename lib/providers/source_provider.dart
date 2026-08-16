import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'package:legado_flutter/application/source_login/source_login_page_port.dart';
import 'package:legado_flutter/application/source_management/source_controller.dart';
import 'package:legado_flutter/application/source_management/source_group_catalog_port.dart';
import 'package:legado_flutter/application/source_management/source_management_book_source_port.dart';
import 'package:legado_flutter/application/source_rules/check_source_prefs_port.dart';
import 'package:legado_flutter/application/source_validation/source_validation_store_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/ports/book_source_validation_port.dart';
import 'package:legado_flutter/domain/repositories/book_source_repository.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/domain/source/source_validation_result.dart';

/// 书源管理的 ChangeNotifier 兼容外观。
///
/// 业务状态由 [SourceController] 唯一持有。旧 Provider、Riverpod
/// Notifier 和仍未迁移的消费者都监听同一份状态，迁移期间不会出现双份书源列表。
class SourceProvider extends ChangeNotifier {
  SourceProvider({
    required BookSourceRepository repository,
    required BookSourceValidationPort validationPort,
    required SourceManagementBookSourcePort sourceService,
    SourceLoginPagePort? loginPort,
    CheckSourcePrefsPort? checkSourcePrefsPort,
    SourceGroupCatalogPort? sourceGroupPort,
    SourceValidationStorePort? validationStorePort,
    Future<List<BookSource>> Function()? builtInSourcesLoader,
  }) : _controller = SourceController(
         repository: repository,
         validationPort: validationPort,
         sourceService: sourceService,
         loginPort: loginPort,
         checkSourcePrefsPort: checkSourcePrefsPort,
         sourceGroupPort: sourceGroupPort,
         validationStorePort: validationStorePort,
         builtInSourcesLoader: builtInSourcesLoader,
       ) {
    _controller.addListener(_onControllerStateChanged);
  }

  final SourceController _controller;

  SourceController get controller => _controller;

  List<BookSource> get sources => _controller.sources;
  BookSourceRepository get repository => _controller.repository;
  Map<String, List<Book>> get searchResults => _controller.searchResults;
  Map<String, SourceValidationResult> get validationResults =>
      _controller.validationResults;
  bool get isLoading => _controller.isLoading;
  bool get isValidating => _controller.isValidating;
  String? get validatingSourceUrl => _controller.validatingSourceUrl;
  String get statusMessage => _controller.statusMessage;
  String? get loadError => _controller.loadError;
  List<String> get knownGroups => _controller.knownGroups;

  SourceValidationResult? validationOf(String sourceUrl) =>
      _controller.validationOf(sourceUrl);

  String? validationProgressOf(String sourceUrl) =>
      _controller.validationProgressOf(sourceUrl);

  Future<void> loadSources() => _controller.loadSources();

  Future<void> ensureBuiltInSources() => _controller.ensureBuiltInSources();

  Future<void> addSource(BookSource source) => _controller.addSource(source);

  Future<void> renameGroup(String oldName, String newName) =>
      _controller.renameGroup(oldName, newName);

  Future<bool> addGroup(String group) => _controller.addGroup(group);

  Future<void> deleteGroup(String groupName) =>
      _controller.deleteGroup(groupName);

  Future<List<BookSource>?> parseSourcesForImport(String text) =>
      _controller.parseSourcesForImport(text);

  Future<bool> importParsedSources(List<BookSource> sources) =>
      _controller.importParsedSources(sources);

  Future<bool> importSources(String jsonText) =>
      _controller.importSources(jsonText);

  Future<bool> importSourcesFromUrl(String url) =>
      _controller.importSourcesFromUrl(url);

  /// 旧文件导入入口保留在兼容外观，平台文件选择不进入 application 层。
  Future<void> importSourcesFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) return;
      await _controller.importSources(await File(path).readAsString());
    } catch (error) {
      debugPrint('  ✗ 文件导入失败: $error');
    }
  }

  Future<void> toggleSource(String sourceUrl, bool enabled) =>
      _controller.toggleSource(sourceUrl, enabled);

  Future<void> deleteSource(String sourceUrl) =>
      _controller.deleteSource(sourceUrl);

  Future<void> setSourcesEnabled(Iterable<String> sourceUrls, bool enabled) =>
      _controller.setSourcesEnabled(sourceUrls, enabled);

  Future<void> deleteSources(Iterable<String> sourceUrls) =>
      _controller.deleteSources(sourceUrls);

  Future<void> setSourcesGroup(Iterable<String> sourceUrls, String group) =>
      _controller.setSourcesGroup(sourceUrls, group);

  Future<void> setSourcesExploreEnabled(Iterable<String> urls, bool enabled) =>
      _controller.setSourcesExploreEnabled(urls, enabled);

  Future<void> moveSourcesToTop(Iterable<String> urls) =>
      _controller.moveSourcesToTop(urls);

  Future<void> moveSourcesToBottom(Iterable<String> urls) =>
      _controller.moveSourcesToBottom(urls);

  Future<void> reorderSources(List<String> orderedUrls) =>
      _controller.reorderSources(orderedUrls);

  Future<String> exportSourcesJson(Iterable<String> urls) =>
      _controller.exportSourcesJson(urls);

  Future<void> addGroupToSources(Iterable<String> urls, String group) =>
      _controller.addGroupToSources(urls, group);

  Future<void> clearGroupOnSources(Iterable<String> urls) =>
      _controller.clearGroupOnSources(urls);

  Future<void> removeGroupTagFromSources(Iterable<String> urls, String tag) =>
      _controller.removeGroupTagFromSources(urls, tag);

  Future<void> updateSource(BookSource source) =>
      _controller.updateSource(source);

  Future<void> searchAll(
    String keyword, {
    String? author,
    bool preciseName = false,
    Set<String>? restrictSourceUrls,
  }) => _controller.searchAll(
    keyword,
    author: author,
    preciseName: preciseName,
    restrictSourceUrls: restrictSourceUrls,
  );

  BookSource? findSourceForBook(Book book) =>
      _controller.findSourceForBook(book);

  Future<Map<String, String>> imageHeadersForSource(BookSource source) =>
      _controller.imageHeadersForSource(source);

  Future<Map<String, String>> imageHeadersForBook(Book book) =>
      _controller.imageHeadersForBook(book);

  Future<SourceValidationResult?> validateSource(
    BookSource source, {
    String? keyword,
  }) => _controller.validateSource(source, keyword: keyword);

  Future<int> validateEnabledSources({
    String? keyword,
    void Function(int done, int total)? onProgress,
  }) => _controller.validateEnabledSources(
    keyword: keyword,
    onProgress: onProgress,
  );

  Future<int> validateSources(
    List<BookSource> sources, {
    String? keyword,
    void Function(int done, int total)? onProgress,
  }) => _controller.validateSources(
    sources,
    keyword: keyword,
    onProgress: onProgress,
  );

  static List<dynamic>? extractSourceListFromDecoded(dynamic decoded) =>
      SourceController.extractSourceListFromDecoded(decoded);

  void _onControllerStateChanged(_) => notifyListeners();

  @override
  void dispose() {
    _controller.removeListener(_onControllerStateChanged);
    super.dispose();
  }
}
