import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/read_style_config.dart';
import '../models/theme_typography.dart';

/// 阅读主题槽位覆盖 + 共用布局（对齐 legado shareLayout / style configs）
abstract final class ReadStylePrefs {
  static const _kShareLayout = 'read_style_share_layout';
  static const _kOverrides = 'read_style_slot_overrides';
  static const _kThemeName = 'read_style_theme_name';
  static const _kTypography = 'read_style_theme_typography';

  /// 合法主题槽：paper / white / dark / green
  static const Set<String> knownThemeNames = {
    'paper',
    'white',
    'dark',
    'green',
  };

  static Future<bool> loadShareLayout() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kShareLayout) ?? true;
  }

  static Future<void> saveShareLayout(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShareLayout, value);
  }

  /// 当前阅读主题槽（含暗黑）；默认 paper
  static Future<String> loadThemeName() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kThemeName);
    if (raw == null || !knownThemeNames.contains(raw)) return 'paper';
    return raw;
  }

  static Future<void> saveThemeName(String themeName) async {
    if (!knownThemeNames.contains(themeName)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeName, themeName);
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

  static Future<Map<String, ThemeTypography>> loadTypographyMap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kTypography);
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return {};
      final out = <String, ThemeTypography>{};
      for (final e in map.entries) {
        if (e.value is Map) {
          out[e.key.toString()] = ThemeTypography.fromJson(
            Map<String, dynamic>.from(e.value as Map),
          );
        }
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  static Future<ThemeTypography?> loadTypography(String themeName) async {
    return (await loadTypographyMap())[themeName];
  }

  static Future<void> saveTypography(
    String themeName,
    ThemeTypography typography,
  ) async {
    if (!knownThemeNames.contains(themeName)) return;
    final all = await loadTypographyMap();
    all[themeName] = typography;
    final prefs = await SharedPreferences.getInstance();
    final map = {
      for (final e in all.entries) e.key: e.value.toJson(),
    };
    await prefs.setString(_kTypography, jsonEncode(map));
  }

  static Future<void> clearTypography(String themeName) async {
    final all = await loadTypographyMap();
    all.remove(themeName);
    final prefs = await SharedPreferences.getInstance();
    final map = {
      for (final e in all.entries) e.key: e.value.toJson(),
    };
    await prefs.setString(_kTypography, jsonEncode(map));
  }
}
