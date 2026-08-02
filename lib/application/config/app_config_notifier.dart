import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_config.dart';
import 'app_config_controller.dart';
import 'app_config_state.dart';

/// 允许页面范围显式绑定既有 AppConfig 单例的依赖入口。
final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.instance);

/// 由 AppConfig 单例构造页面范围内唯一的状态桥接 controller。
final appConfigControllerProvider = Provider<AppConfigController>((ref) {
  final controller = AppConfigController(config: ref.watch(appConfigProvider));
  ref.onDispose(controller.dispose);
  return controller;
}, dependencies: [appConfigProvider]);

/// AppConfig 的 Riverpod 状态入口。
final appConfigNotifierProvider =
    NotifierProvider<AppConfigNotifier, AppConfigState>(
      AppConfigNotifier.new,
      dependencies: [appConfigControllerProvider],
    );

/// 发布既有 AppConfig 单例的状态并转发配置命令。
class AppConfigNotifier extends Notifier<AppConfigState> {
  late AppConfigController _controller;

  AppConfigController get controller => _controller;

  @override
  AppConfigState build() {
    _controller = ref.watch(appConfigControllerProvider);
    void onStateChanged(AppConfigState next) => state = next;

    _controller.addListener(onStateChanged);
    ref.onDispose(() => _controller.removeListener(onStateChanged));
    return _controller.state;
  }

  Future<void> load() => _controller.load();

  Future<void> setShowDiscovery(bool value) =>
      _controller.setShowDiscovery(value);

  Future<void> setShowRSS(bool value) => _controller.setShowRSS(value);

  Future<void> setDefaultHomePage(String value) =>
      _controller.setDefaultHomePage(value);

  Future<void> setSyncBookProgress(bool value) =>
      _controller.setSyncBookProgress(value);
}
