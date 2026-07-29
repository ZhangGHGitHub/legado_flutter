import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/lifecycle/app_lifecycle_coordinator.dart';

void main() {
  test('tracks lifecycle phase and resume transitions', () {
    final coordinator = AppLifecycleCoordinator();
    var notifications = 0;
    coordinator.addListener(() => notifications++);

    expect(coordinator.phase, ApplicationLifecyclePhase.resumed);
    expect(coordinator.resumeCount, 0);

    coordinator.update(ApplicationLifecyclePhase.paused);
    expect(coordinator.phase, ApplicationLifecyclePhase.paused);
    expect(coordinator.resumeCount, 0);

    coordinator.update(ApplicationLifecyclePhase.paused);
    expect(notifications, 1);

    coordinator.update(ApplicationLifecyclePhase.resumed);
    expect(coordinator.isResumed, isTrue);
    expect(coordinator.resumeCount, 1);
    expect(notifications, 2);
  });
}
