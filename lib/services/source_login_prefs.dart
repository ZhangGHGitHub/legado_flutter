import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 书源登录信息持久化（对齐 legado `getLoginInfoMap` / `putLoginInfo`）
class SourceLoginPrefs {
  static String _key(String bookSourceUrl) =>
      'source_login_info_${Uri.encodeComponent(bookSourceUrl)}';

  static Future<Map<String, String>> load(String bookSourceUrl) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key(bookSourceUrl));
    if (raw == null || raw.isEmpty) return {};
    try {
      final obj = jsonDecode(raw);
      if (obj is! Map) return {};
      return obj.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
    } catch (_) {
      return {};
    }
  }

  static Future<void> save(
    String bookSourceUrl,
    Map<String, String> info,
  ) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key(bookSourceUrl), jsonEncode(info));
  }

  static Future<void> clear(String bookSourceUrl) async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key(bookSourceUrl));
  }
}
