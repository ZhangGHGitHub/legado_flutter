import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/crash/crash_report.dart';
import 'package:legado_flutter/infrastructure/preferences/shared_preferences_crash_report_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('round-trips the latest report and consumes only its marker', () async {
    const store = SharedPreferencesCrashReportStore();
    final report = _report();

    await store.writePending(report);
    expect((await store.readPending())?.error, 'boom');
    expect((await store.readLatest())?.startupStage, '书架加载');

    await store.acknowledgePending();
    expect(await store.readPending(), isNull);
    expect((await store.readLatest())?.error, 'boom');

    await store.clear();
    expect(await store.readLatest(), isNull);
  });

  test(
    'malformed persisted JSON is ignored and its marker is consumed',
    () async {
      SharedPreferences.setMockInitialValues({
        'legado_latest_crash_report': jsonEncode({'occurredAt': 'invalid'}),
        'legado_crash_report_pending': true,
      });
      const store = SharedPreferencesCrashReportStore();

      expect(await store.readPending(), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('legado_crash_report_pending'), isFalse);
    },
  );
}

CrashReport _report() => CrashReport(
  occurredAt: DateTime(2026, 7, 29, 12),
  origin: CrashOrigin.flutterFramework,
  startupStage: '书架加载',
  error: 'boom',
  stackTrace: 'stack',
  metadata: const CrashRuntimeMetadata(
    platform: 'windows',
    platformVersion: 'test',
    appVersion: '1.0.0+1',
    engineVersion: '0.5.6',
  ),
);
