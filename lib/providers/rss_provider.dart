import 'package:flutter/foundation.dart';

import '../application/rss/rss_controller.dart';
import '../application/rss/rss_source_store_port.dart';
import '../domain/ports/rss_source_import_port.dart';
import 'package:legado_flutter/domain/rss/rss_source.dart';

/// RSS 订阅源管理的 ChangeNotifier 兼容外观。
///
/// 新页面使用 application 层控制器/Notifier；旧页面、启动任务和服务仍可
/// 通过此外观保留原有调用签名，迁移期间两者共享同一份状态。
class RssProvider extends ChangeNotifier {
  RssProvider({
    RssSourceImportPort? sourceImportPort,
    RssSourceStorePort? sourceStore,
    RssSourceController? controller,
  }) : _controller =
           controller ??
           RssSourceController(
             sourceImportPort: sourceImportPort,
             sourceStore: sourceStore,
           ) {
    _controller.addListener(_onControllerStateChanged);
  }

  final RssSourceController _controller;

  RssSourceController get controller => _controller;
  List<RssSource> get sources => _controller.sources;

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

  void _onControllerStateChanged(_) => notifyListeners();

  @override
  void dispose() {
    _controller.removeListener(_onControllerStateChanged);
    super.dispose();
  }
}
