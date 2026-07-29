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
}

class DiagnosticRecord {
  DiagnosticRecord({
    required this.time,
    required this.severity,
    required String message,
    this.category = 'app',
    this.source,
    Map<String, String> metadata = const {},
    String? error,
    String? stackTrace,
    this.runtime = const DiagnosticRuntimeInfo.unavailable(),
  }) : message = sanitize(message, maxLength: maxMessageLength),
       error = error == null
           ? null
           : sanitize(error, maxLength: maxErrorLength),
       stackTrace = stackTrace == null
           ? null
           : sanitize(stackTrace, maxLength: maxStackLength),
       metadata = _sanitizeMetadata(metadata);

  static const maxEntries = 100;
  static const maxPersistedBytes = 64 * 1024;
  static const maxLineLength = 4096;
  static const maxMessageLength = 2048;
  static const maxErrorLength = 4096;
  static const maxStackLength = 32 * 1024;
  static const maxMetadataValueLength = 512;

  final DateTime time;
  final DiagnosticSeverity severity;
  final String category;
  final String? source;
  final String message;
  final Map<String, String> metadata;
  final String? error;
  final String? stackTrace;
  final DiagnosticRuntimeInfo runtime;

  String get line {
    final t =
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
    final extra = <String>[];
    if (category != 'app') extra.add('category=$category');
    final s = source;
    if (s != null && s.isNotEmpty) extra.add('source=${sanitize(s)}');
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
