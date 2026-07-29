import '../../domain/crash/crash_report.dart';
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

  static const _maxErrorLength = 4096;
  static const _maxStackLength = 32 * 1024;
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
        startupStage: _truncate(_startupStage, _maxMetadataLength),
        error: _truncate(error.toString(), _maxErrorLength),
        stackTrace: _truncate(stackTrace.toString(), _maxStackLength),
        metadata: CrashRuntimeMetadata(
          platform: _truncate(metadata.platform, _maxMetadataLength),
          platformVersion: _truncate(
            metadata.platformVersion,
            _maxMetadataLength,
          ),
          appVersion: _truncate(metadata.appVersion, _maxMetadataLength),
          engineVersion: _truncate(metadata.engineVersion, _maxMetadataLength),
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

  static String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) return value;
    var end = maxLength;
    final previous = value.codeUnitAt(end - 1);
    final next = value.codeUnitAt(end);
    if (_isHighSurrogate(previous) && _isLowSurrogate(next)) {
      end -= 1;
    }
    return value.substring(0, end);
  }

  static bool _isHighSurrogate(int codeUnit) =>
      codeUnit >= 0xD800 && codeUnit <= 0xDBFF;

  static bool _isLowSurrogate(int codeUnit) =>
      codeUnit >= 0xDC00 && codeUnit <= 0xDFFF;
}
