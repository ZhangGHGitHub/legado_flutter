import '../../config/app_config.dart';
import 'app_config_state.dart';

typedef AppConfigStateListener = void Function(AppConfigState state);

/// 将既有 AppConfig 单例接入 application 状态边界。
///
/// AppConfig 继续负责实际值、SharedPreferencesRuntime 持久化和并发去重；
/// controller 只监听它并发布不可变快照，所有写操作也原样委托给单例。
final class AppConfigController {
  AppConfigController({AppConfig? config})
    : _config = config ?? AppConfig.instance {
    _state = _snapshot(
      loadStatus: _config.isLoaded
          ? AppConfigLoadStatus.loaded
          : AppConfigLoadStatus.initial,
    );
    _config.addListener(_handleConfigChanged);
  }

  final AppConfig _config;
  final Set<AppConfigStateListener> _listeners = {};
  late AppConfigState _state;
  bool _disposed = false;

  AppConfigState get state => _state;

  void addListener(AppConfigStateListener listener) {
    if (_disposed) return;
    _listeners.add(listener);
  }

  void removeListener(AppConfigStateListener listener) {
    _listeners.remove(listener);
  }

  /// 保留 AppConfig 的 load 并发去重和失败重试语义。
  Future<void> load() async {
    if (!_config.isLoaded) {
      _publish(
        _snapshot(loadStatus: AppConfigLoadStatus.loading, loadError: null),
      );
    }

    try {
      await _config.load();
      _publish(_snapshot(loadStatus: AppConfigLoadStatus.loaded));
    } catch (error) {
      _publish(
        _snapshot(loadStatus: AppConfigLoadStatus.failure, loadError: error),
      );
      rethrow;
    }
  }

  Future<void> setShowDiscovery(bool value) => _config.setShowDiscovery(value);

  Future<void> setShowRSS(bool value) => _config.setShowRSS(value);

  Future<void> setDefaultHomePage(String value) =>
      _config.setDefaultHomePage(value);

  Future<void> setSyncBookProgress(bool value) =>
      _config.setSyncBookProgress(value);

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _config.removeListener(_handleConfigChanged);
    _listeners.clear();
  }

  void _handleConfigChanged() {
    final loadStatus = _config.isLoaded
        ? AppConfigLoadStatus.loaded
        : _state.loadStatus == AppConfigLoadStatus.loading
        ? AppConfigLoadStatus.loading
        : _state.loadStatus == AppConfigLoadStatus.failure
        ? AppConfigLoadStatus.failure
        : AppConfigLoadStatus.initial;
    _publish(
      _snapshot(
        loadStatus: loadStatus,
        loadError: loadStatus == AppConfigLoadStatus.failure
            ? _state.loadError
            : null,
      ),
    );
  }

  AppConfigState _snapshot({
    required AppConfigLoadStatus loadStatus,
    Object? loadError,
  }) => AppConfigState(
    showDiscovery: _config.showDiscovery,
    showRSS: _config.showRSS,
    defaultHomePage: _config.defaultHomePage,
    syncBookProgress: _config.syncBookProgress,
    loadStatus: loadStatus,
    loadError: loadError,
  );

  void _publish(AppConfigState next) {
    if (next == _state) return;
    _state = next;
    for (final listener in List<AppConfigStateListener>.of(_listeners)) {
      listener(_state);
    }
  }
}
