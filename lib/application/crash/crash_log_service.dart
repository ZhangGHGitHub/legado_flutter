import '../../domain/crash/crash_report.dart';
import '../../domain/diagnostics/diagnostic_record.dart';
import '../../domain/ports/crash_report_store.dart';

typedef CrashMetadataLoader = Future<CrashRuntimeMetadata> Function();

class CrashLogService {
  CrashLogService({
    required CrashReportStore store,
    required CrashMetadataLoader metadataLoader,
    DateTime Function()? clock,
  }) : _store = store,
       _metadataLoader = metadataLoader,
       _clock = clock ?? DateTime.now;

  static const _maxMetadataLength = 2048;

  final CrashReportStore _store;
  final CrashMetadataLoader _metadataLoader;
  final DateTime Function() _clock;

  String _startupStage = '进程入口';

  String get startupStage => _startupStage;

  void updateStartupStage(String stage) {
    final normalized = stage.trim();
    _startupStage = normalized.isEmpty ? 'unknown' : normalized;
  }

  Future<bool> record({
    required Object error,
    required StackTrace stackTrace,
    required CrashOrigin origin,
  }) async {
    try {
      final metadata = await _safeMetadata();
      final report = CrashReport(
        occurredAt: _clock(),
        origin: origin,
        startupStage: DiagnosticRecord.sanitize(
          _startupStage,
          maxLength: _maxMetadataLength,
        ),
        error: DiagnosticRecord.sanitize(
          error.toString(),
          maxLength: DiagnosticRecord.maxErrorLength,
        ),
        stackTrace: DiagnosticRecord.sanitize(
          stackTrace.toString(),
          maxLength: DiagnosticRecord.maxStackLength,
        ),
        metadata: CrashRuntimeMetadata(
          platform: DiagnosticRecord.sanitize(
            metadata.platform,
            maxLength: _maxMetadataLength,
          ),
          platformVersion: DiagnosticRecord.sanitize(
            metadata.platformVersion,
            maxLength: _maxMetadataLength,
          ),
          appVersion: DiagnosticRecord.sanitize(
            metadata.appVersion,
            maxLength: _maxMetadataLength,
          ),
          engineVersion: DiagnosticRecord.sanitize(
            metadata.engineVersion,
            maxLength: _maxMetadataLength,
          ),
        ),
      );
      await _store.writePending(report);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<CrashReport?> pendingReport() async {
    try {
      return await _store.readPending();
    } catch (_) {
      return null;
    }
  }

  Future<CrashReport?> latestReport() async {
    try {
      return await _store.readLatest();
    } catch (_) {
      return null;
    }
  }

  Future<bool> acknowledgePending() async {
    try {
      await _store.acknowledgePending();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> clear() async {
    try {
      await _store.clear();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<CrashRuntimeMetadata> _safeMetadata() async {
    try {
      return await _metadataLoader();
    } catch (_) {
      return const CrashRuntimeMetadata.unavailable();
    }
  }
}
