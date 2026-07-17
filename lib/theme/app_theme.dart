import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'color_presets.dart';
import 'legado_tokens.dart';
import 'theme_config_model.dart';
import '../services/reader_font_loader.dart';

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

    // Jingshiro ThemeStore：
    // - TitleBar / 状态栏 ≈ primary（深色条）
    // - bottomBackground ≠ primary（浅底栏）
    // - 选中 Tab / Switch ≈ accent（secondary），无大块 MD3 pill
    final primaryIsLight =
        ThemeData.estimateBrightnessForColor(scheme.primary) ==
            Brightness.light;
    final onBar = scheme.onPrimary;
    final accent = scheme.secondary;
    // 底栏：自定义 bottomBackground，或略区别于内容区 surface
    final bottomBg = customColors['bottomBackground'] ??
        (brightness == Brightness.light
            ? Color.alphaBlend(
                const Color(0x14000000),
                scheme.surface,
              )
            : scheme.surfaceContainerLow);
    final bottomUnselected = brightness == Brightness.light
        ? const Color(0x8A000000) // md secondary text on light
        : scheme.onSurfaceVariant;
    final primaryDark = Color.lerp(scheme.primary, Colors.black, 0.2)!;
    // 对齐 Jingshiro 系统无衬线：避免 Windows 西文+中文 fallback 混用导致字显细/不一致
    final uiFont = ReaderFontLoader.platformSansFamily();
    final uiFallback = ReaderFontLoader.cjkFallbackFamilies();
    TextStyle uiStyle({
      required Color color,
      required double size,
      FontWeight weight = FontWeight.w400,
      double height = 1.2,
    }) {
      return TextStyle(
        color: color,
        fontSize: size,
        fontWeight: weight,
        height: height,
        fontFamily: uiFont,
        fontFamilyFallback: uiFallback,
      );
    }

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: uiFont,
      // 触控热区：桌面由 LegadoChrome 再收紧；移动端保持 Material 默认
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
            fontFamily: uiFont,
            fontFamilyFallback: uiFallback,
            bodyColor: scheme.onSurface,
            displayColor: scheme.onSurface,
          ),
      appBarTheme: AppBarTheme(
        // Jingshiro TitleBar：内容偏左；ToolbarTitle = 22sp
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.primary,
        foregroundColor: onBar,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        iconTheme: IconThemeData(color: onBar, size: 24),
        actionsIconTheme: IconThemeData(color: onBar, size: 24),
        titleTextStyle: uiStyle(
          color: onBar,
          size: 20,
          weight: FontWeight.w400,
          height: 1.25,
        ),
        // 基准；运行时 LegadoChrome 覆盖 — 给标题上下留白
        toolbarHeight: LegadoTokens.toolbarHeight,
        systemOverlayStyle: SystemUiOverlayStyle(
          // 对齐 setStatusBarColorAuto(primaryDark / primary)
          statusBarColor: primaryDark,
          statusBarIconBrightness:
              primaryIsLight ? Brightness.dark : Brightness.light,
          statusBarBrightness:
              primaryIsLight ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: bottomBg,
          systemNavigationBarIconBrightness: brightness == Brightness.light
              ? Brightness.dark
              : Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: LegadoTokens.cardRadius),
        margin: const EdgeInsets.symmetric(
          horizontal: LegadoTokens.spacingSm,
          vertical: LegadoTokens.spacingXs,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        // 对齐 activity_main：minHeight 64 + labeled
        elevation: 2,
        // 基准；运行时 LegadoChrome 覆盖 — 底栏文字上下留白
        height: 64,
        backgroundColor: bottomBg,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black26,
        indicatorColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        // MD3 默认 labelPadding 上下 4px → 图标与文字空隙过大；Jingshiro 几乎无缝
        labelPadding: EdgeInsets.zero,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? accent : bottomUnselected,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return uiStyle(
            color: selected ? accent : bottomUnselected,
            size: 12,
            weight: FontWeight.w400,
            height: 1.0,
          );
        }),
      ),
      bottomAppBarTheme: BottomAppBarThemeData(
        color: bottomBg,
        elevation: 2,
        surfaceTintColor: Colors.transparent,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: onBar,
        unselectedLabelColor: onBar.withValues(alpha: 0.72),
        indicatorColor: onBar,
        dividerColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.4),
        space: 1,
        thickness: 1,
      ),
    );
  }
}
