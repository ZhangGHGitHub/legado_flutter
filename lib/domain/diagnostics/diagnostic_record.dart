import 'package:freezed_annotation/freezed_annotation.dart';

part 'diagnostic_record.freezed.dart';

enum DiagnosticSeverity {
  info('I'),
  warning('W'),
  error('E');

  const DiagnosticSeverity(this.level);

  final String level;

  static DiagnosticSeverity fromLevel(String level) {
    return switch (level.toUpperCase()) {
      'E' => DiagnosticSeverity.error,
      'W' => DiagnosticSeverity.warning,
      _ => DiagnosticSeverity.info,
    };
  }
}

class DiagnosticRuntimeInfo {
  const DiagnosticRuntimeInfo({
    required this.platform,
    required this.platformVersion,
    required this.appVersion,
    required this.engineVersion,
  });

  const DiagnosticRuntimeInfo.unavailable()
    : platform = 'unknown',
      platformVersion = 'unknown',
      appVersion = 'unknown',
      engineVersion = 'unavailable';

  final String platform;
  final String platformVersion;
  final String appVersion;
  final String engineVersion;

  DiagnosticRuntimeInfo copyWith({
    String? platform,
    String? platformVersion,
    String? appVersion,
    String? engineVersion,
  }) => DiagnosticRuntimeInfo(
    platform: platform ?? this.platform,
    platformVersion: platformVersion ?? this.platformVersion,
    appVersion: appVersion ?? this.appVersion,
    engineVersion: engineVersion ?? this.engineVersion,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiagnosticRuntimeInfo &&
          other.platform == platform &&
          other.platformVersion == platformVersion &&
          other.appVersion == appVersion &&
          other.engineVersion == engineVersion;

  @override
  int get hashCode =>
      Object.hash(platform, platformVersion, appVersion, engineVersion);
}

@freezed
class DiagnosticRecord with _$DiagnosticRecord {
  const DiagnosticRecord._();

  factory DiagnosticRecord({
    required DateTime time,
    required DiagnosticSeverity severity,
    required String message,
    String category = 'app',
    String? source,
    Map<String, String> metadata = const {},
    String? error,
    String? stackTrace,
    DiagnosticRuntimeInfo runtime = const DiagnosticRuntimeInfo.unavailable(),
  }) => DiagnosticRecord._create(
    time: time,
    severity: severity,
    message: sanitize(message, maxLength: maxMessageLength),
    category: category,
    source: source,
    metadata: _sanitizeMetadata(metadata),
    error: error == null ? null : sanitize(error, maxLength: maxErrorLength),
    stackTrace: stackTrace == null
        ? null
        : sanitize(stackTrace, maxLength: maxStackLength),
    runtime: runtime,
  );

  factory DiagnosticRecord._create({
    required DateTime time,
    required DiagnosticSeverity severity,
    required String message,
    required String category,
    String? source,
    required Map<String, String> metadata,
    String? error,
    String? stackTrace,
    required DiagnosticRuntimeInfo runtime,
  }) = _DiagnosticRecord;

  static const maxEntries = 100;
  static const maxPersistedBytes = 64 * 1024;
  static const maxLineLength = 4096;
  static const maxMessageLength = 2048;
  static const maxErrorLength = 4096;
  static const maxStackLength = 32 * 1024;
  static const maxMetadataValueLength = 512;

  String get line {
    final t =
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
    final extra = <String>[];
    if (category != 'app') extra.add('category=$category');
    final s = source;
    if (s != null && s.isNotEmpty) extra.add('source=${sanitize(s)}');
    if (runtime.platform != 'unknown') {
      extra.add('platform=${sanitize(runtime.platform)}');
      extra.add('platformVersion=${sanitize(runtime.platformVersion)}');
      extra.add('appVersion=${sanitize(runtime.appVersion)}');
      extra.add('engineVersion=${sanitize(runtime.engineVersion)}');
    }
    for (final entry in metadata.entries) {
      extra.add('${sanitize(entry.key)}=${sanitize(entry.value)}');
    }
    final suffix = extra.isEmpty ? '' : ' ${extra.join(' ')}';
    return truncateUtf16Safe(
      '[$t][${severity.level}] $message$suffix',
      maxLineLength,
    );
  }

  String get displayText {
    final lines = <String>[
      'time=${time.toIso8601String()}',
      'level=${severity.level}',
      'category=$category',
    ];
    final s = source;
    if (s != null && s.isNotEmpty) lines.add('source=${sanitize(s)}');
    lines.addAll([
      'platform=${sanitize(runtime.platform)}',
      'platformVersion=${sanitize(runtime.platformVersion)}',
      'appVersion=${sanitize(runtime.appVersion)}',
      'engineVersion=${sanitize(runtime.engineVersion)}',
    ]);
    for (final entry in metadata.entries) {
      lines.add('${sanitize(entry.key)}=${sanitize(entry.value)}');
    }
    lines.add('');
    lines.add(message);
    final e = error;
    if (e != null && e.isNotEmpty && e != message) {
      lines.add('');
      lines.add(e);
    }
    final stack = stackTrace;
    if (stack != null && stack.isNotEmpty) {
      lines.add('');
      lines.add(stack);
    }
    return lines.join('\n');
  }

  static String sanitize(
    String value, {
    int maxLength = maxMetadataValueLength,
  }) {
    var sanitized = value
        .replaceAllMapped(
          RegExp(
            r'(authorization\s*[:=]\s*bearer\s+)([^\s,;]+)',
            caseSensitive: false,
          ),
          (match) => '${match.group(1)}<redacted>',
        )
        .replaceAllMapped(
          RegExp(
            r'\b(token|access_token|password|passwd|secret|cookie)\s*[:=]\s*([^\s,;&]+)',
            caseSensitive: false,
          ),
          (match) => '${match.group(1)}=<redacted>',
        );
    return truncateUtf16Safe(sanitized, maxLength);
  }

  static String truncateUtf16Safe(String value, int maxLength) {
    if (value.length <= maxLength) return value;
    var end = maxLength;
    final previous = value.codeUnitAt(end - 1);
    final next = value.codeUnitAt(end);
    if (_isHighSurrogate(previous) && _isLowSurrogate(next)) {
      end -= 1;
    }
    return value.substring(0, end);
  }

  static Map<String, String> _sanitizeMetadata(Map<String, String> metadata) {
    return Map.unmodifiable(
      metadata.map(
        (key, value) => MapEntry(
          sanitize(key, maxLength: maxMetadataValueLength),
          sanitize(value, maxLength: maxMetadataValueLength),
        ),
      ),
    );
  }

  static bool _isHighSurrogate(int codeUnit) =>
      codeUnit >= 0xD800 && codeUnit <= 0xDBFF;

  static bool _isLowSurrogate(int codeUnit) =>
      codeUnit >= 0xDC00 && codeUnit <= 0xDFFF;
}
