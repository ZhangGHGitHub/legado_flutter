import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/crash/crash_log_service.dart';
import 'package:legado_flutter/domain/crash/crash_report.dart';
import 'package:legado_flutter/domain/ports/crash_report_store.dart';
import 'package:legado_flutter/infrastructure/platform/global_crash_handler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('installs, chains, captures, and restores global handlers', () async {
    final originalFlutter = FlutterError.onError;
    final originalPlatform = PlatformDispatcher.instance.onError;
    var flutterChained = false;
    var platformChained = false;
    FlutterError.onError = (_) => flutterChained = true;
    PlatformDispatcher.instance.onError = (_, _) {
      platformChained = true;
      return true;
    };

    final store = _RecordingStore();
    final service = CrashLogService(
      store: store,
      metadataLoader: () async => const CrashRuntimeMetadata.unavailable(),
    );
    final handler = GlobalCrashHandler(crashLog: service)..install();
    try {
      FlutterError.onError!(
        FlutterErrorDetails(
          exception: StateError('framework'),
          stack: StackTrace.current,
        ),
      );
      expect(
        PlatformDispatcher.instance.onError!(
          StateError('platform'),
          StackTrace.current,
        ),
        isTrue,
      );
      handler.handleZoneError(StateError('zone'), StackTrace.current);

      await store.waitForWrites(3);
      expect(flutterChained, isTrue);
      expect(platformChained, isTrue);
      expect(store.origins, [
        CrashOrigin.flutterFramework,
        CrashOrigin.platformDispatcher,
        CrashOrigin.unhandledZone,
      ]);
    } finally {
      handler.restore();
      FlutterError.onError = originalFlutter;
      PlatformDispatcher.instance.onError = originalPlatform;
    }
  });
}

class _RecordingStore implements CrashReportStore {
  final reports = <CrashReport>[];
  final _writes = StreamController<int>.broadcast();

  List<CrashOrigin> get origins =>
      reports.map((report) => report.origin).toList();

  Future<void> waitForWrites(int count) async {
    if (reports.length >= count) return;
    await _writes.stream.firstWhere((written) => written >= count);
  }

  @override
  Future<void> writePending(CrashReport report) async {
    reports.add(report);
    _writes.add(reports.length);
  }

  @override
  Future<void> acknowledgePending() async {}

  @override
  Future<void> clear() async => reports.clear();

  @override
  Future<CrashReport?> readLatest() async => reports.lastOrNull;

  @override
  Future<CrashReport?> readPending() async => reports.lastOrNull;
}
