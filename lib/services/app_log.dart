import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../domain/diagnostics/diagnostic_record.dart';
import '../application/preferences/shared_preferences_runtime.dart';

/// 应用运行日志 — 对齐 Jingshiro [AppLog]：内存环缓冲最多 100 条，最新在前。
class AppLogEntry {
  const AppLogEntry({
    required this.time,
    required this.level,
    required this.message,
    this.category = 'app',
    this.source,
    this.metadata = const {},
    this.runtime = const DiagnosticRuntimeInfo.unavailable(),
  });

  final DateTime time;
  final String level;
  final String message;
  final String category;
  final String? source;
  final Map<String, String> metadata;
  final DiagnosticRuntimeInfo runtime;

  DiagnosticRecord get record => DiagnosticRecord(
    time: time,
    severity: DiagnosticSeverity.fromLevel(level),
    message: message,
    category: category,
    source: source,
    metadata: metadata,
    runtime: runtime,
  );

  String get line {
    return record.line;
  }
}

abstract final class AppLog {
  static const _prefsKey = 'legado_app_log_lines';
  static const _maxEntries = DiagnosticRecord.maxEntries;
  static const _maxPersistedBytes = DiagnosticRecord.maxPersistedBytes;
  static final List<AppLogEntry> _entries = [];
  static bool _loaded = false;
  static DiagnosticRuntimeInfo _runtime =
      const DiagnosticRuntimeInfo.unavailable();

  /// 最新在前
  static List<AppLogEntry> get entries => List.unmodifiable(_entries);

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferencesRuntime.getOrNull();
      final raw = prefs?.getStringList(_prefsKey) ?? const [];
      for (final line in raw.take(_maxEntries)) {
        _entries.add(
          AppLogEntry(
            time: DateTime.now(),
            level: 'I',
            message: line,
            runtime: _runtime,
          ),
        );
      }
    } catch (_) {}
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferencesRuntime.getOrNull();
      var bytes = 0;
      final lines = <String>[];
      for (final entry in _entries) {
        final line = entry.line;
        final lineBytes = utf8.encode(line).length + 1;
        if (lines.isNotEmpty && bytes + lineBytes > _maxPersistedBytes) {
          break;
        }
        lines.add(line);
        bytes += lineBytes;
      }
      await prefs?.setStringList(_prefsKey, lines);
    } catch (_) {}
  }

  static Future<void> put(
    String message, {
    String level = 'I',
    String category = 'app',
    String? source,
    Map<String, String> metadata = const {},
  }) async {
    await ensureLoaded();
    final entry = AppLogEntry(
      time: DateTime.now(),
      level: level,
      message: message,
      category: category,
      source: source,
      metadata: metadata,
      runtime: _runtime,
    );
    _entries.insert(0, entry);
    while (_entries.length > _maxEntries) {
      _entries.removeLast();
    }
    debugPrint('[AppLog] ${entry.line}');
    await _persist();
  }

  static Future<void> i(
    String message, {
    String category = 'app',
    String? source,
    Map<String, String> metadata = const {},
  }) => put(
    message,
    level: 'I',
    category: category,
    source: source,
    metadata: metadata,
  );
  static Future<void> w(
    String message, {
    String category = 'app',
    String? source,
    Map<String, String> metadata = const {},
  }) => put(
    message,
    level: 'W',
    category: category,
    source: source,
    metadata: metadata,
  );
  static Future<void> e(
    String message, {
    String category = 'app',
    String? source,
    Map<String, String> metadata = const {},
  }) => put(
    message,
    level: 'E',
    category: category,
    source: source,
    metadata: metadata,
  );

  static Future<void> clear() async {
    _entries.clear();
    await _persist();
  }

  static void configureRuntime(DiagnosticRuntimeInfo runtime) {
    _runtime = runtime;
  }

  @visibleForTesting
  static void resetForTest() {
    _entries.clear();
    _loaded = false;
    _runtime = const DiagnosticRuntimeInfo.unavailable();
  }
}
