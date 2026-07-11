import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'legado_tokens.dart';

const _seedColor = Color(0xFF2196F3);
const _themeModeKey = 'legado_theme_mode';

/// 主题模式：跟随系统 / 浅色 / 深色
enum LegadoThemeMode { system, light, dark }

/// 全局主题模式（我的 → 主题模式）
class ThemeModeController extends ChangeNotifier {
  LegadoThemeMode _mode = LegadoThemeMode.system;

  LegadoThemeMode get mode => _mode;

  ThemeMode get materialThemeMode => switch (_mode) {
        LegadoThemeMode.system => ThemeMode.system,
        LegadoThemeMode.light => ThemeMode.light,
        LegadoThemeMode.dark => ThemeMode.dark,
      };

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_themeModeKey);
    _mode = LegadoThemeMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => LegadoThemeMode.system,
    );
    notifyListeners();
  }

  Future<void> setMode(LegadoThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }
}

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    );
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
      navigationBarTheme: NavigationBarThemeData(
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
