import 'package:flutter/foundation.dart';

import '../application/preferences/shared_preferences_runtime.dart';

/// 应用运行日志 — 对齐 Jingshiro [AppLog]：内存环缓冲最多 100 条，最新在前。
class AppLogEntry {
  final DateTime time;
  final String level;
  final String message;

  const AppLogEntry({
    required this.time,
    required this.level,
    required this.message,
  });

  String get line {
    final t =
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
    return '[$t][$level] $message';
  }
}

abstract final class AppLog {
  static const _prefsKey = 'legado_app_log_lines';
  static const _maxEntries = 100;
  static final List<AppLogEntry> _entries = [];
  static bool _loaded = false;

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
          AppLogEntry(time: DateTime.now(), level: 'I', message: line),
        );
      }
    } catch (_) {}
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferencesRuntime.getOrNull();
      await prefs?.setStringList(
        _prefsKey,
        _entries.map((e) => e.line).toList(growable: false),
      );
    } catch (_) {}
  }

  static Future<void> put(String message, {String level = 'I'}) async {
    await ensureLoaded();
    _entries.insert(
      0,
      AppLogEntry(time: DateTime.now(), level: level, message: message),
    );
    while (_entries.length > _maxEntries) {
      _entries.removeLast();
    }
    debugPrint('[AppLog][$level] $message');
    await _persist();
  }

  static Future<void> i(String message) => put(message, level: 'I');
  static Future<void> w(String message) => put(message, level: 'W');
  static Future<void> e(String message) => put(message, level: 'E');

  static Future<void> clear() async {
    _entries.clear();
    await _persist();
  }
}
