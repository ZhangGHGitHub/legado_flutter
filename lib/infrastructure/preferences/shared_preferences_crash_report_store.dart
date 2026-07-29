import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/crash/crash_report.dart';
import '../../domain/ports/crash_report_store.dart';

class SharedPreferencesCrashReportStore implements CrashReportStore {
  const SharedPreferencesCrashReportStore();

  static const _reportKey = 'legado_latest_crash_report';
  static const _pendingKey = 'legado_crash_report_pending';

  @override
  Future<CrashReport?> readLatest() async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getString(_reportKey));
  }

  @override
  Future<CrashReport?> readPending() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_pendingKey) != true) return null;
    final report = _decode(prefs.getString(_reportKey));
    if (report != null) return report;
    await prefs.setBool(_pendingKey, false);
    return null;
  }

  @override
  Future<void> writePending(CrashReport report) async {
    final prefs = await SharedPreferences.getInstance();
    await _requireSuccess(
      prefs.setString(_reportKey, jsonEncode(report.toJson())),
      '写入崩溃报告失败',
    );
    await _requireSuccess(prefs.setBool(_pendingKey, true), '写入崩溃标记失败');
  }

  @override
  Future<void> acknowledgePending() async {
    final prefs = await SharedPreferences.getInstance();
    await _requireSuccess(prefs.setBool(_pendingKey, false), '清除崩溃标记失败');
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await _requireSuccess(prefs.remove(_reportKey), '清除崩溃报告失败');
    await _requireSuccess(prefs.remove(_pendingKey), '清除崩溃标记失败');
  }

  static CrashReport? _decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return CrashReport.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _requireSuccess(
    Future<bool> operation,
    String message,
  ) async {
    if (!await operation) throw StateError(message);
  }
}
