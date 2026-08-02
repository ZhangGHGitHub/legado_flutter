import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/diagnostics/diagnostic_record.dart';

void main() {
  test('keeps runtime defaults and provides value semantics', () {
    const runtime = DiagnosticRuntimeInfo.unavailable();

    expect(runtime.platform, 'unknown');
    expect(runtime.platformVersion, 'unknown');
    expect(runtime.appVersion, 'unknown');
    expect(runtime.engineVersion, 'unavailable');
    expect(
      runtime.copyWith(engineVersion: '0.5.6'),
      const DiagnosticRuntimeInfo(
        platform: 'unknown',
        platformVersion: 'unknown',
        appVersion: 'unknown',
        engineVersion: '0.5.6',
      ),
    );
  });

  test('provides value semantics without changing sanitized fields', () {
    final record = DiagnosticRecord(
      time: DateTime(2026, 7, 30, 12, 34, 56),
      severity: DiagnosticSeverity.warning,
      message: 'token=secret',
      metadata: const {'key': 'value'},
    );

    expect(record.message, 'token=<redacted>');
    expect(
      record.copyWith(severity: DiagnosticSeverity.error),
      record.copyWith(severity: DiagnosticSeverity.error),
    );
    expect(
      record.copyWith(severity: DiagnosticSeverity.error).message,
      'token=<redacted>',
    );
  });

  test('sanitizes sensitive values and keeps UTF-16 truncation safe', () {
    final value = DiagnosticRecord.sanitize(
      'token=abc123 password:secret Authorization: Bearer bearer-secret',
      maxLength: 200,
    );

    expect(value, contains('token=<redacted>'));
    expect(value, contains('password=<redacted>'));
    expect(value, contains('Authorization: Bearer <redacted>'));
    expect(value, isNot(contains('abc123')));
    expect(value, isNot(contains('bearer-secret')));

    final truncated = DiagnosticRecord.truncateUtf16Safe('${'x' * 7}😀', 8);
    expect(truncated, 'x' * 7);
  });

  test('formats line and display text with runtime metadata', () {
    final record = DiagnosticRecord(
      time: DateTime(2026, 7, 30, 12, 34, 56),
      severity: DiagnosticSeverity.error,
      category: 'crash',
      source: 'unhandled_zone',
      message: 'boom token=secret',
      metadata: const {'startupStage': '书架加载'},
      stackTrace: 'stack password=secret',
      runtime: const DiagnosticRuntimeInfo(
        platform: 'windows',
        platformVersion: 'test',
        appVersion: '1.0.0+1',
        engineVersion: '0.5.6',
      ),
    );

    expect(record.line, startsWith('[12:34:56][E] boom token=<redacted>'));
    expect(record.line, contains('category=crash'));
    expect(record.displayText, contains('platform=windows'));
    expect(record.displayText, contains('engineVersion=0.5.6'));
    expect(record.displayText, isNot(contains('password=secret')));
  });
}
