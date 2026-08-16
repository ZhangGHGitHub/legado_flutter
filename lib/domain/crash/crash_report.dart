import 'package:freezed_annotation/freezed_annotation.dart';

import '../diagnostics/diagnostic_record.dart';

part 'crash_report.freezed.dart';

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

  CrashRuntimeMetadata copyWith({
    String? platform,
    String? platformVersion,
    String? appVersion,
    String? engineVersion,
  }) => CrashRuntimeMetadata(
    platform: platform ?? this.platform,
    platformVersion: platformVersion ?? this.platformVersion,
    appVersion: appVersion ?? this.appVersion,
    engineVersion: engineVersion ?? this.engineVersion,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CrashRuntimeMetadata &&
          other.platform == platform &&
          other.platformVersion == platformVersion &&
          other.appVersion == appVersion &&
          other.engineVersion == engineVersion;

  @override
  int get hashCode =>
      Object.hash(platform, platformVersion, appVersion, engineVersion);
}

@freezed
class CrashReport with _$CrashReport {
  const factory CrashReport({
    required DateTime occurredAt,
    required CrashOrigin origin,
    required String startupStage,
    required String error,
    required String stackTrace,
    required CrashRuntimeMetadata metadata,
  }) = _CrashReport;

  const CrashReport._();

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
