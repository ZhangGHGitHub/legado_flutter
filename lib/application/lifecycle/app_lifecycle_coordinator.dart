import 'package:flutter/foundation.dart';

enum ApplicationLifecyclePhase { resumed, inactive, hidden, paused, detached }

/// 应用级生命周期协调器。页面订阅此状态，不直接注册全局 Flutter 回调。
class AppLifecycleCoordinator extends ChangeNotifier {
  ApplicationLifecyclePhase _phase = ApplicationLifecyclePhase.resumed;
  int _resumeCount = 0;

  ApplicationLifecyclePhase get phase => _phase;
  int get resumeCount => _resumeCount;
  bool get isResumed => _phase == ApplicationLifecyclePhase.resumed;

  void update(ApplicationLifecyclePhase phase) {
    if (_phase == phase) return;
    _phase = phase;
    if (phase == ApplicationLifecyclePhase.resumed) {
      _resumeCount++;
    }
    notifyListeners();
  }
}
