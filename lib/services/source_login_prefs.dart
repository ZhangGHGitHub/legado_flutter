import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 书源/RSS 源登录信息与登录头 — 对齐 legado `getLoginInfo` / `getLoginHeader`
class SourceLoginPrefs {
  static Future<SharedPreferences?> _prefsOrNull() async {
    try {
      return await SharedPreferences.getInstance();
    } on MissingPluginException {
      // Pure Dart/FFI tests do not register the platform plugin. In that
      // environment the original app semantics are simply "no saved login".
      return null;
    }
  }

  static String _infoKey(String sourceUrl) =>
      'source_login_info_${Uri.encodeComponent(sourceUrl)}';

  static String _headerKey(String sourceUrl) =>
      'source_login_header_${Uri.encodeComponent(sourceUrl)}';

  static Future<Map<String, String>> load(String sourceUrl) async {
    final p = await _prefsOrNull();
    if (p == null) return {};
    final raw = p.getString(_infoKey(sourceUrl));
    if (raw == null || raw.isEmpty) return {};
    try {
      final obj = jsonDecode(raw);
      if (obj is! Map) return {};
      return obj.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
    } catch (_) {
      return {};
    }
  }

  static Future<void> save(String sourceUrl, Map<String, String> info) async {
    final p = await _prefsOrNull();
    if (p == null) return;
    await p.setString(_infoKey(sourceUrl), jsonEncode(info));
  }

  static Future<void> clear(String sourceUrl) async {
    final p = await _prefsOrNull();
    if (p == null) return;
    await p.remove(_infoKey(sourceUrl));
  }

  static Future<String?> loadHeader(String sourceUrl) async {
    final p = await _prefsOrNull();
    if (p == null) return null;
    return p.getString(_headerKey(sourceUrl));
  }

  static Future<void> saveHeader(String sourceUrl, String header) async {
    final p = await _prefsOrNull();
    if (p == null) return;
    await p.setString(_headerKey(sourceUrl), header);
  }

  static Future<void> clearHeader(String sourceUrl) async {
    final p = await _prefsOrNull();
    if (p == null) return;
    await p.remove(_headerKey(sourceUrl));
  }

  /// 解析登录头：JSON 头 map，或非 JSON 时当作 Cookie 串（对齐 Rust `login_header_map`）
  static Map<String, String> parseLoginHeader(String loginHeader) {
    final t = loginHeader.trim();
    if (t.isEmpty) return {};
    try {
      final v = jsonDecode(t);
      if (v is Map) {
        final out = <String, String>{};
        for (final e in v.entries) {
          final s = e.value?.toString() ?? '';
          if (s.isNotEmpty) out[e.key.toString()] = s;
        }
        return out;
      }
    } catch (_) {}
    return {'Cookie': t};
  }

  /// 将登录头合并进书源 JSON 的 `header`（登录头覆盖同名键）
  static String mergeLoginHeaderIntoSourceJson(
    String sourceJson,
    String? loginHeader,
  ) {
    final lh = loginHeader?.trim();
    if (lh == null || lh.isEmpty) return sourceJson;
    final loginMap = parseLoginHeader(lh);
    if (loginMap.isEmpty) return sourceJson;

    Map<String, dynamic> obj;
    try {
      final decoded = jsonDecode(sourceJson);
      if (decoded is! Map) return sourceJson;
      obj = Map<String, dynamic>.from(decoded);
    } catch (_) {
      return sourceJson;
    }

    final merged = <String, String>{};
    final existing = obj['header'];
    if (existing is Map) {
      for (final e in existing.entries) {
        final s = e.value?.toString() ?? '';
        if (s.isNotEmpty) merged[e.key.toString()] = s;
      }
    } else if (existing is String && existing.trim().isNotEmpty) {
      try {
        final parsed = jsonDecode(existing);
        if (parsed is Map) {
          for (final e in parsed.entries) {
            final s = e.value?.toString() ?? '';
            if (s.isNotEmpty) merged[e.key.toString()] = s;
          }
        }
      } catch (_) {}
    }
    merged.addAll(loginMap);
    obj['header'] = merged;
    return jsonEncode(obj);
  }
}
