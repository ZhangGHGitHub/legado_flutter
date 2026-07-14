import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/read_style_config.dart';

/// 阅读主题槽位覆盖 + 共用布局（对齐 legado shareLayout / style configs）
abstract final class ReadStylePrefs {
  static const _kShareLayout = 'read_style_share_layout';
  static const _kOverrides = 'read_style_slot_overrides';

  static Future<bool> loadShareLayout() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kShareLayout) ?? true;
  }

  static Future<void> saveShareLayout(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShareLayout, value);
  }

  static Future<Map<String, ReadStyleSlotOverride>> loadOverrides() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kOverrides);
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return {};
      final out = <String, ReadStyleSlotOverride>{};
      for (final e in map.entries) {
        if (e.value is Map) {
          out[e.key.toString()] = ReadStyleSlotOverride.fromJson(
            Map<String, dynamic>.from(e.value as Map),
          );
        }
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveOverrides(
    Map<String, ReadStyleSlotOverride> overrides,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final map = {
      for (final e in overrides.entries) e.key: e.value.toJson(),
    };
    await prefs.setString(_kOverrides, jsonEncode(map));
  }

  static Future<void> upsertOverride(
    String themeName,
    ReadStyleSlotOverride override,
  ) async {
    final all = await loadOverrides();
    all[themeName] = override;
    await saveOverrides(all);
  }

  static Future<void> clearOverride(String themeName) async {
    final all = await loadOverrides();
    all.remove(themeName);
    await saveOverrides(all);
  }
}
