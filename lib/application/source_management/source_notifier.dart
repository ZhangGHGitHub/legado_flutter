import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/book/book.dart';
import '../../domain/repositories/book_source_repository.dart';
import '../../domain/source/book_source.dart';
import '../../domain/source/source_validation_result.dart';
import 'source_controller.dart';
import 'source_state.dart';

/// Riverpod 迁移期间由组合根提供的共享书源控制器。
final sourceControllerProvider = Provider<SourceController>(
  (ref) => throw StateError('未提供 SourceController'),
);

/// 书源管理的 Riverpod 状态入口。
final sourceNotifierProvider = NotifierProvider<SourceNotifier, SourceState>(
  SourceNotifier.new,
  dependencies: [sourceControllerProvider],
);

/// 只发布共享控制器状态，并转发书源管理命令。
class SourceNotifier extends Notifier<SourceState> {
  late SourceController _controller;

  List<BookSource> get sources => state.sources;
  Map<String, List<Book>> get searchResults => state.searchResults;
  Map<String, SourceValidationResult> get validationResults =>
      state.validationResults;
  Map<String, String> get validationProgress => state.validationProgress;
  bool get isLoading => state.isLoading;
  bool get isValidating => state.isValidating;
  String? get validatingSourceUrl => state.validatingSourceUrl;
  String get statusMessage => state.statusMessage;
  String? get loadError => state.loadError;
  List<String> get knownGroups => _controller.knownGroups;
  BookSourceRepository get repository => _controller.repository;

  @override
  SourceState build() {
    _controller = ref.watch(sourceControllerProvider);
    void onStateChanged(SourceState next) {
      state = next;
    }

    _controller.addListener(onStateChanged);
    ref.onDispose(() => _controller.removeListener(onStateChanged));
    return _controller.state;
  }

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
}
