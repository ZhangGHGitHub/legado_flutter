import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/crash/crash_log_service.dart';
import 'package:legado_flutter/domain/crash/crash_report.dart';
import 'package:legado_flutter/domain/ports/crash_report_store.dart';

void main() {
  test('records bounded crash data with stage and runtime metadata', () async {
    final store = _MemoryCrashReportStore();
    final service = CrashLogService(
      store: store,
      metadataLoader: () async => const CrashRuntimeMetadata(
        platform: 'windows',
        platformVersion: 'test-platform',
        appVersion: '1.0.0+1',
        engineVersion: '0.5.6',
      ),
      clock: () => DateTime(2026, 7, 29, 12),
    );
    service.updateStartupStage(' Rust 数据库初始化 ');

    final saved = await service.record(
      error: StateError('x' * 5000),
      stackTrace: StackTrace.fromString('s' * 40000),
      origin: CrashOrigin.unhandledZone,
    );

    expect(saved, isTrue);
    final report = store.latest!;
    expect(report.occurredAt, DateTime(2026, 7, 29, 12));
    expect(report.origin, CrashOrigin.unhandledZone);
    expect(report.startupStage, 'Rust 数据库初始化');
    expect(report.metadata.engineVersion, '0.5.6');
    expect(report.error.length, 4096);
    expect(report.stackTrace.length, 32 * 1024);
    expect(await service.pendingReport(), same(report));
  });

  test('bounded fields never split a UTF-16 surrogate pair', () async {
    final store = _MemoryCrashReportStore();
    final service = CrashLogService(
      store: store,
      metadataLoader: () async => const CrashRuntimeMetadata.unavailable(),
    );
    await service.record(
      error: '${'x' * 4095}😀',
      stackTrace: StackTrace.current,
      origin: CrashOrigin.unhandledZone,
    );

    expect(store.latest?.error, 'x' * 4095);
  });

  test('metadata and storage failures degrade without throwing', () async {
    final metadataFallbackStore = _MemoryCrashReportStore();
    final metadataFallback = CrashLogService(
      store: metadataFallbackStore,
      metadataLoader: () => throw StateError('metadata unavailable'),
    );
    expect(
      await metadataFallback.record(
        error: 'failure',
        stackTrace: StackTrace.current,
        origin: CrashOrigin.flutterFramework,
      ),
      isTrue,
    );
    expect(metadataFallbackStore.latest?.metadata.platform, 'unknown');

    final failed = CrashLogService(
      store: _FailingCrashReportStore(),
      metadataLoader: () async => const CrashRuntimeMetadata.unavailable(),
    );
    expect(
      await failed.record(
        error: 'failure',
        stackTrace: StackTrace.current,
        origin: CrashOrigin.platformDispatcher,
      ),
      isFalse,
    );
    expect(await failed.pendingReport(), isNull);
    expect(await failed.latestReport(), isNull);
    expect(await failed.acknowledgePending(), isFalse);
    expect(await failed.clear(), isFalse);
  });

  test('acknowledging clears only the one-shot marker', () async {
    final store = _MemoryCrashReportStore();
    final service = CrashLogService(
      store: store,
      metadataLoader: () async => const CrashRuntimeMetadata.unavailable(),
    );
    await service.record(
      error: 'failure',
      stackTrace: StackTrace.current,
      origin: CrashOrigin.unhandledZone,
    );

    expect(await service.acknowledgePending(), isTrue);
    expect(await service.pendingReport(), isNull);
    expect(await service.latestReport(), isNotNull);
  });
}

class _MemoryCrashReportStore implements CrashReportStore {
  CrashReport? latest;
  bool pending = false;

  @override
  Future<void> acknowledgePending() async => pending = false;

  @override
  Future<void> clear() async {
    latest = null;
    pending = false;
  }

  @override
  Future<CrashReport?> readLatest() async => latest;

  @override
  Future<CrashReport?> readPending() async => pending ? latest : null;

  @override
  Future<void> writePending(CrashReport report) async {
    latest = report;
    pending = true;
  }
}

class _FailingCrashReportStore implements CrashReportStore {
  Never _fail() => throw StateError('store unavailable');

  @override
  Future<void> acknowledgePending() async => _fail();

  @override
  Future<void> clear() async => _fail();

  @override
  Future<CrashReport?> readLatest() async => _fail();

  @override
  Future<CrashReport?> readPending() async => _fail();

  @override
  Future<void> writePending(CrashReport report) async => _fail();
}
