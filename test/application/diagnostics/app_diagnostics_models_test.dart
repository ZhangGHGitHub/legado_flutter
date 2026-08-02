import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/diagnostics/app_diagnostics_monitor.dart';

void main() {
  group('AppDiagnosticsConfig Freezed contract', () {
    test('keeps the existing defaults and disabled constructor', () {
      const config = AppDiagnosticsConfig();

      expect(config.enabled, isFalse);
      expect(config.recordFrames, isTrue);
      expect(config.recordFreeze, isTrue);
      expect(config.recordDispatchers, isTrue);
      expect(config.recordStartupTasks, isTrue);
      expect(config.frameBudget, const Duration(milliseconds: 16));
      expect(config.freezeProbeInterval, const Duration(seconds: 3));
      expect(config.freezeTolerance, const Duration(milliseconds: 300));
      expect(config.dispatcherTimeout, const Duration(seconds: 5));
      expect(const AppDiagnosticsConfig.disabled().enabled, isFalse);
    });

    test('has value equality and copyWith semantics', () {
      const config = AppDiagnosticsConfig(enabled: true);

      expect(config, equals(const AppDiagnosticsConfig(enabled: true)));
      expect(config.copyWith(recordFrames: false).recordFrames, isFalse);
    });
  });

  group('AppDiagnosticEvent Freezed contract', () {
    final occurredAt = DateTime(2026, 8, 3, 12);
    final event = AppDiagnosticEvent(
      kind: AppDiagnosticEventKind.slowFrame,
      source: 'flutter.frame',
      message: '检测到慢帧',
      occurredAt: occurredAt,
      duration: Duration(milliseconds: 34),
      threshold: Duration(milliseconds: 16),
    );

    test('has value equality and copyWith semantics', () {
      expect(event, equals(event.copyWith()));
      expect(
        event.copyWith(duration: const Duration(milliseconds: 35)).duration,
        const Duration(milliseconds: 35),
      );
    });

    test('keeps diagnostic level and excludes error details from log line', () {
      final sensitiveEvent = event.copyWith(
        error: StateError('token=secret-value'),
        stackTrace: StackTrace.fromString('password=secret-value'),
      );
      final line = sensitiveEvent.toLogLine();

      expect(sensitiveEvent.isCrash, isFalse);
      expect(sensitiveEvent.level, 'W');
      expect(line, contains('kind=slowFrame'));
      expect(line, contains('durationMs=34'));
      expect(line, contains('thresholdMs=16'));
      expect(line, isNot(contains('secret-value')));
    });
  });
}
