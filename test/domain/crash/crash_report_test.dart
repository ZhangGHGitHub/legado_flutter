import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/crash/crash_report.dart';

void main() {
  group('CrashRuntimeMetadata', () {
    test('keeps unavailable defaults and has value semantics', () {
      const metadata = CrashRuntimeMetadata.unavailable();

      expect(metadata.platform, 'unknown');
      expect(metadata.platformVersion, 'unknown');
      expect(metadata.appVersion, 'unknown');
      expect(metadata.engineVersion, 'unavailable');
      expect(
        metadata.copyWith(appVersion: '1.0.0'),
        const CrashRuntimeMetadata(
          platform: 'unknown',
          platformVersion: 'unknown',
          appVersion: '1.0.0',
          engineVersion: 'unavailable',
        ),
      );
    });
  });

  group('CrashReport', () {
    final occurredAt = DateTime.utc(2026, 8, 2, 12, 34, 56);

    test('round-trips every persisted JSON field', () {
      final report = CrashReport(
        occurredAt: occurredAt,
        origin: CrashOrigin.platformDispatcher,
        startupStage: '书架加载',
        error: 'boom',
        stackTrace: 'stack',
        metadata: const CrashRuntimeMetadata(
          platform: 'windows',
          platformVersion: '11',
          appVersion: '1.0.0+1',
          engineVersion: '0.5.6',
        ),
      );

      final restored = CrashReport.fromJson(report.toJson());
      expect(restored.toJson(), report.toJson());
      expect(restored.occurredAt.toUtc(), report.occurredAt.toUtc());
      expect(report.toJson(), {
        'occurredAt': '2026-08-02T12:34:56.000Z',
        'origin': 'platform_dispatcher',
        'startupStage': '书架加载',
        'error': 'boom',
        'stackTrace': 'stack',
        'platform': 'windows',
        'platformVersion': '11',
        'appVersion': '1.0.0+1',
        'engineVersion': '0.5.6',
      });
    });

    test('keeps legacy defaults and invalid-time error text', () {
      final report = CrashReport.fromJson({
        'occurredAt': occurredAt.toIso8601String(),
      });

      expect(report.origin, CrashOrigin.unhandledZone);
      expect(report.startupStage, 'unknown');
      expect(report.error, 'unknown');
      expect(report.stackTrace, isEmpty);
      expect(report.metadata, const CrashRuntimeMetadata.unavailable());
      expect(
        () => CrashReport.fromJson(const {'occurredAt': 'invalid'}),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            '崩溃时间无效',
          ),
        ),
      );
    });

    test('keeps display text compatible with diagnostics', () {
      final report = CrashReport(
        occurredAt: occurredAt,
        origin: CrashOrigin.unhandledZone,
        startupStage: 'bootstrap',
        error: 'boom',
        stackTrace: 'stack',
        metadata: const CrashRuntimeMetadata.unavailable(),
      );

      expect(report.displayText, contains('category=crash'));
      expect(report.displayText, contains('source=unhandled_zone'));
      expect(report.displayText, contains('startupStage=bootstrap'));
      expect(report.displayText, contains('boom'));
      expect(report.displayText, contains('stack'));
    });
  });
}
