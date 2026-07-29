import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/diagnostics/app_diagnostics_monitor.dart';
import 'package:legado_flutter/application/startup/startup_task_runner.dart';

void main() {
  test('disabled diagnostics does not emit events', () async {
    final recorded = <AppDiagnosticEvent>[];
    final monitor = AppDiagnosticsMonitor(
      config: const AppDiagnosticsConfig.disabled(),
      sink: recorded.add,
    );

    final event = await monitor.recordFrameTiming(
      buildDuration: const Duration(milliseconds: 20),
      rasterDuration: const Duration(milliseconds: 20),
      totalSpan: const Duration(milliseconds: 50),
    );

    expect(event, isNull);
    expect(recorded, isEmpty);
    expect(monitor.events, isEmpty);
  });

  test('records slow frames and freeze samples when enabled', () async {
    final recorded = <AppDiagnosticEvent>[];
    final monitor = AppDiagnosticsMonitor(
      config: const AppDiagnosticsConfig(enabled: true),
      sink: recorded.add,
      clock: () => DateTime(2026, 7, 30, 10),
    );

    final frame = await monitor.recordFrameTiming(
      buildDuration: const Duration(milliseconds: 12),
      rasterDuration: const Duration(milliseconds: 18),
      totalSpan: const Duration(milliseconds: 34),
    );
    final freeze = await monitor.recordFreezeSample(
      elapsed: const Duration(milliseconds: 3401),
      expectedInterval: const Duration(seconds: 3),
    );

    expect(frame?.kind, AppDiagnosticEventKind.slowFrame);
    expect(freeze?.kind, AppDiagnosticEventKind.appFreeze);
    expect(recorded, hasLength(2));
    expect(recorded.first.toLogLine(), contains('slowFrame'));
    expect(recorded.last.toLogLine(), contains('appFreeze'));
    expect(recorded.every((event) => event.isCrash), isFalse);
  });

  test(
    'records dispatcher and startup task timeouts as diagnostics only',
    () async {
      final recorded = <AppDiagnosticEvent>[];
      final monitor = AppDiagnosticsMonitor(
        config: const AppDiagnosticsConfig(enabled: true),
        sink: recorded.add,
        clock: () => DateTime(2026, 7, 30, 11),
      );

      final dispatcher = await monitor.recordDispatcherTimeout(
        dispatcher: 'main',
        waited: const Duration(seconds: 5),
      );
      final startup = await monitor.recordStartupTask(
        StartupTaskReport(
          id: 'bookshelf.maintenance',
          status: StartupTaskStatus.failed,
          attempt: 1,
          startedAt: DateTime(2026, 7, 30, 10, 59, 30),
          finishedAt: DateTime(2026, 7, 30, 11),
          error: TimeoutException('Future not completed'),
        ),
      );

      expect(dispatcher?.kind, AppDiagnosticEventKind.dispatcherTimeout);
      expect(startup?.kind, AppDiagnosticEventKind.startupTaskTimeout);
      expect(recorded, hasLength(2));
      expect(recorded.map((event) => event.isCrash), everyElement(isFalse));
      expect(recorded.last.toLogLine(), contains('bookshelf.maintenance'));
    },
  );
}
