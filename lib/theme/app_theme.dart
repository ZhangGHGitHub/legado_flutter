import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'color_presets.dart';
import 'legado_tokens.dart';
import 'theme_config_model.dart';

const _themeModeKey = 'legado_theme_mode';
const _colorPresetKey = 'legado_color_preset';
const _customColorsKey = 'legado_theme_custom_colors';

/// 主题模式：跟随系统 / 浅色 / 深色
enum LegadoThemeMode { system, light, dark }

/// 全局主题（明暗模式 + MD3 配色预设 + 12 色自定义）
class ThemeModeController extends ChangeNotifier {
  LegadoThemeMode _mode = LegadoThemeMode.system;
  LegadoColorPreset _preset = LegadoColorPreset.light;
  Map<String, Color> _customColors = {};

  LegadoThemeMode get mode => _mode;
  LegadoColorPreset get preset => _preset;
  Map<String, Color> get customColors => Map.unmodifiable(_customColors);

  ThemeMode get materialThemeMode => switch (_mode) {
        LegadoThemeMode.system => ThemeMode.system,
        LegadoThemeMode.light => ThemeMode.light,
        LegadoThemeMode.dark => ThemeMode.dark,
      };

  String get presetLabel => LegadoColorPresets.infoFor(_preset).label;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawMode = prefs.getString(_themeModeKey);
    _mode = LegadoThemeMode.values.firstWhere(
      (m) => m.name == rawMode,
      orElse: () => LegadoThemeMode.system,
    );
    _preset = LegadoColorPresets.parse(prefs.getString(_colorPresetKey));
    final colorsJson = prefs.getString(_customColorsKey);
    if (colorsJson != null && colorsJson.isNotEmpty) {
      final map = jsonDecode(colorsJson) as Map<String, dynamic>;
      _customColors = ThemeColorRoles.colorsFromHex(map);
    } else {
      _customColors = {};
    }
    notifyListeners();
  }

  Future<void> _persistCustomColors() async {
    final prefs = await SharedPreferences.getInstance();
    if (_customColors.isEmpty) {
      await prefs.remove(_customColorsKey);
      return;
    }
    await prefs.setString(
      _customColorsKey,
      jsonEncode(ThemeColorRoles.colorsToHex(_customColors)),
    );
  }

  Future<void> setMode(LegadoThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  Future<void> setPreset(LegadoColorPreset preset) async {
    _preset = preset;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_colorPresetKey, preset.name);
  }

  Future<void> setCustomColor(String role, Color? color) async {
    if (color == null) {
      _customColors.remove(role);
    } else {
      _customColors[role] = color;
    }
    notifyListeners();
    await _persistCustomColors();
  }

  Future<void> setCustomColors(Map<String, Color> colors) async {
    _customColors = Map.from(colors);
    notifyListeners();
    await _persistCustomColors();
  }

  Future<void> clearCustomColors() async {
    _customColors = {};
    notifyListeners();
    await _persistCustomColors();
  }

  LegadoThemeConfig exportThemeConfig() {
    return LegadoThemeConfig(
      mode: _mode.name,
      preset: _preset.name,
      colors: _customColors,
    );
  }

  Map<String, dynamic> exportConfig() => exportThemeConfig().toJson();
}

abstract final class AppTheme {
  static ThemeData light({
    LegadoColorPreset preset = LegadoColorPreset.light,
    Map<String, Color> customColors = const {},
    ColorScheme? dynamicLight,
    ColorScheme? dynamicDark,
  }) =>
      _build(
        preset: preset,
        brightness: Brightness.light,
        customColors: customColors,
        dynamicLight: dynamicLight,
        dynamicDark: dynamicDark,
      );

  static ThemeData dark({
    LegadoColorPreset preset = LegadoColorPreset.light,
    Map<String, Color> customColors = const {},
    ColorScheme? dynamicLight,
    ColorScheme? dynamicDark,
  }) =>
      _build(
        preset: preset,
        brightness: Brightness.dark,
        customColors: customColors,
        dynamicLight: dynamicLight,
        dynamicDark: dynamicDark,
      );

  static ThemeData _build({
    required LegadoColorPreset preset,
    required Brightness brightness,
    Map<String, Color> customColors = const {},
    ColorScheme? dynamicLight,
    ColorScheme? dynamicDark,
  }) {
    var scheme = LegadoColorPresets.schemeFor(
      preset,
      brightness,
      dynamicLight: dynamicLight,
      dynamicDark: dynamicDark,
    );
    scheme = ThemeColorRoles.applyOverrides(scheme, customColors);
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: LegadoTokens.cardRadius),
        margin: const EdgeInsets.symmetric(
          horizontal: LegadoTokens.spacingSm,
          vertical: LegadoTokens.spacingXs,
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.4),
        space: 1,
        thickness: 1,
      ),
    );
  }
}
