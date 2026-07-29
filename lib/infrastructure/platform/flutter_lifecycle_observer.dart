import 'package:flutter/widgets.dart';

import '../../application/lifecycle/app_lifecycle_coordinator.dart';

/// Flutter 平台生命周期适配器，只负责把宿主回调转为 application 状态。
class FlutterLifecycleObserver with WidgetsBindingObserver {
  FlutterLifecycleObserver(this._coordinator);

  final AppLifecycleCoordinator _coordinator;
  bool _started = false;

  void start() {
    if (_started) return;
    WidgetsBinding.instance.addObserver(this);
    _started = true;
  }

  void stop() {
    if (!_started) return;
    WidgetsBinding.instance.removeObserver(this);
    _started = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _coordinator.update(_mapState(state));
  }

  static ApplicationLifecyclePhase _mapState(AppLifecycleState state) {
    return switch (state) {
      AppLifecycleState.resumed => ApplicationLifecyclePhase.resumed,
      AppLifecycleState.inactive => ApplicationLifecyclePhase.inactive,
      AppLifecycleState.hidden => ApplicationLifecyclePhase.hidden,
      AppLifecycleState.paused => ApplicationLifecyclePhase.paused,
      AppLifecycleState.detached => ApplicationLifecyclePhase.detached,
    };
  }
}
