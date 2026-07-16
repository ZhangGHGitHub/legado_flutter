import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 书源/RSS 源登录信息与登录头 — 对齐 legado `getLoginInfo` / `getLoginHeader`
class SourceLoginPrefs {
  static String _infoKey(String sourceUrl) =>
      'source_login_info_${Uri.encodeComponent(sourceUrl)}';

  static String _headerKey(String sourceUrl) =>
      'source_login_header_${Uri.encodeComponent(sourceUrl)}';

  static Future<Map<String, String>> load(String sourceUrl) async {
    final p = await SharedPreferences.getInstance();
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
    final p = await SharedPreferences.getInstance();
    await p.setString(_infoKey(sourceUrl), jsonEncode(info));
  }

  static Future<void> clear(String sourceUrl) async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_infoKey(sourceUrl));
  }

  static Future<String?> loadHeader(String sourceUrl) async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_headerKey(sourceUrl));
  }

  static Future<void> saveHeader(String sourceUrl, String header) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_headerKey(sourceUrl), header);
  }

  static Future<void> clearHeader(String sourceUrl) async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_headerKey(sourceUrl));
  }
}
