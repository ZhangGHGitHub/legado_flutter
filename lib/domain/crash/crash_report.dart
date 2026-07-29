import '../diagnostics/diagnostic_record.dart';

enum CrashOrigin {
  flutterFramework('flutter_framework'),
  platformDispatcher('platform_dispatcher'),
  unhandledZone('unhandled_zone');

  const CrashOrigin(this.storageValue);

  final String storageValue;

  static CrashOrigin fromStorageValue(String value) {
    return CrashOrigin.values.firstWhere(
      (origin) => origin.storageValue == value,
      orElse: () => CrashOrigin.unhandledZone,
    );
  }
}

class CrashRuntimeMetadata {
  const CrashRuntimeMetadata({
    required this.platform,
    required this.platformVersion,
    required this.appVersion,
    required this.engineVersion,
  });

  const CrashRuntimeMetadata.unavailable()
    : platform = 'unknown',
      platformVersion = 'unknown',
      appVersion = 'unknown',
      engineVersion = 'unavailable';

  final String platform;
  final String platformVersion;
  final String appVersion;
  final String engineVersion;
}

class CrashReport {
  const CrashReport({
    required this.occurredAt,
    required this.origin,
    required this.startupStage,
    required this.error,
    required this.stackTrace,
    required this.metadata,
  });

  final DateTime occurredAt;
  final CrashOrigin origin;
  final String startupStage;
  final String error;
  final String stackTrace;
  final CrashRuntimeMetadata metadata;

  String get displayText => DiagnosticRecord(
    time: occurredAt,
    severity: DiagnosticSeverity.error,
    category: 'crash',
    source: origin.storageValue,
    message: error,
    stackTrace: stackTrace,
    metadata: {'startupStage': startupStage},
    runtime: DiagnosticRuntimeInfo(
      platform: metadata.platform,
      platformVersion: metadata.platformVersion,
      appVersion: metadata.appVersion,
      engineVersion: metadata.engineVersion,
    ),
  ).displayText;

  Map<String, dynamic> toJson() => {
    'occurredAt': occurredAt.toUtc().toIso8601String(),
    'origin': origin.storageValue,
    'startupStage': startupStage,
    'error': error,
    'stackTrace': stackTrace,
    'platform': metadata.platform,
    'platformVersion': metadata.platformVersion,
    'appVersion': metadata.appVersion,
    'engineVersion': metadata.engineVersion,
  };

  factory CrashReport.fromJson(Map<String, dynamic> json) {
    final occurredAt = DateTime.tryParse(json['occurredAt'] as String? ?? '');
    if (occurredAt == null) {
      throw const FormatException('崩溃时间无效');
    }
    return CrashReport(
      occurredAt: occurredAt.toLocal(),
      origin: CrashOrigin.fromStorageValue(json['origin'] as String? ?? ''),
      startupStage: json['startupStage'] as String? ?? 'unknown',
      error: json['error'] as String? ?? 'unknown',
      stackTrace: json['stackTrace'] as String? ?? '',
      metadata: CrashRuntimeMetadata(
        platform: json['platform'] as String? ?? 'unknown',
        platformVersion: json['platformVersion'] as String? ?? 'unknown',
        appVersion: json['appVersion'] as String? ?? 'unknown',
        engineVersion: json['engineVersion'] as String? ?? 'unavailable',
      ),
    );
  }
}
