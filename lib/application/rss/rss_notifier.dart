import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/rss/rss_source.dart';
import 'rss_controller.dart';
import 'rss_state.dart';

/// RSS 页面局部覆盖的共享控制器入口。
final rssSourceControllerProvider = Provider<RssSourceController>(
  (ref) => throw StateError('未提供 RssSourceController'),
);

final rssNotifierProvider = NotifierProvider<RssNotifier, RssState>(
  RssNotifier.new,
  dependencies: [rssSourceControllerProvider],
);

/// RSS 源管理页面的 Riverpod 状态入口。
class RssNotifier extends Notifier<RssState> {
  late RssSourceController _controller;

  List<RssSource> get sources => state.sources;

  @override
  RssState build() {
    _controller = ref.watch(rssSourceControllerProvider);
    void onStateChanged(RssState next) {
      state = next;
    }

    _controller.addListener(onStateChanged);
    ref.onDispose(() => _controller.removeListener(onStateChanged));
    return _controller.state;
  }

  Future<void> loadSources() => _controller.loadSources();

  List<RssSource> enabledSources({String? searchKey}) =>
      _controller.enabledSources(searchKey: searchKey);

  List<String> enabledGroups() => _controller.enabledGroups();

  List<String> allGroups() => _controller.allGroups();

  List<RssSource> managedSources({String? searchKey, String filter = 'all'}) =>
      _controller.managedSources(searchKey: searchKey, filter: filter);

  Future<void> setEnabled(RssSource source, bool enabled) =>
      _controller.setEnabled(source, enabled);

  Future<void> setEnabledMany(Iterable<String> urls, bool enabled) =>
      _controller.setEnabledMany(urls, enabled);

  Future<void> deleteSources(Iterable<String> urls) =>
      _controller.deleteSources(urls);

  Future<void> topSources(Iterable<String> urls) =>
      _controller.topSources(urls);

  Future<bool> importSourcesFromUrl(String url) =>
      _controller.importSourcesFromUrl(url);

  Future<void> upsertSource(RssSource source) =>
      _controller.upsertSource(source);

  Future<bool> importSources(String jsonText) =>
      _controller.importSources(jsonText);

  Future<void> topSource(RssSource source) => _controller.topSource(source);

  Future<void> disableSource(RssSource source) =>
      _controller.disableSource(source);

  Future<void> deleteSource(RssSource source) =>
      _controller.deleteSource(source);
}
