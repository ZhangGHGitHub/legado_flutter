import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/preferences/shared_preferences_runtime.dart';
import 'package:legado_flutter/domain/diagnostics/diagnostic_record.dart';
import 'package:legado_flutter/services/app_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferencesRuntime.resetForTest();
    SharedPreferences.setMockInitialValues({});
    AppLog.resetForTest();
  });

  tearDown(() {
    AppLog.resetForTest();
    SharedPreferencesRuntime.resetForTest();
  });

  test('redacts log lines and keeps the newest bounded entries', () async {
    await AppLog.put('token=abc123', level: 'W');
    expect(AppLog.entries.single.line, contains('[W] token=<redacted>'));
    expect(AppLog.entries.single.line, isNot(contains('abc123')));

    for (var i = 0; i < DiagnosticRecord.maxEntries + 5; i++) {
      await AppLog.put('line $i');
    }

    expect(AppLog.entries, hasLength(DiagnosticRecord.maxEntries));
    expect(AppLog.entries.first.line, contains('line 104'));
    expect(AppLog.entries.last.line, contains('line 5'));
  });

  test('persisted log text stays within the diagnostic byte budget', () async {
    for (var i = 0; i < 120; i++) {
      await AppLog.put('line-$i ${'x' * 900}');
    }

    final prefs = await SharedPreferences.getInstance();
    final lines = prefs.getStringList('legado_app_log_lines') ?? const [];
    final bytes = lines.fold<int>(0, (sum, line) => sum + line.length + 1);

    expect(lines.length, lessThanOrEqualTo(DiagnosticRecord.maxEntries));
    expect(bytes, lessThanOrEqualTo(DiagnosticRecord.maxPersistedBytes));
  });
}
