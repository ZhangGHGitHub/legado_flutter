import 'package:flutter/material.dart';

/// MD3 十二色板角色（Phase 4.1）
class ThemeColorRole {
  final String id;
  final String label;

  const ThemeColorRole(this.id, this.label);
}

abstract final class ThemeColorRoles {
  static const List<ThemeColorRole> all = [
    ThemeColorRole('primary', '主色（顶栏）'),
    ThemeColorRole('onPrimary', '主色文字'),
    ThemeColorRole('secondary', '强调色（底栏选中）'),
    ThemeColorRole('onSecondary', '强调色文字'),
    ThemeColorRole('tertiary', '第三色'),
    ThemeColorRole('onTertiary', '第三色文字'),
    ThemeColorRole('error', '错误色'),
    ThemeColorRole('onError', '错误文字'),
    ThemeColorRole('surface', '表面（内容区）'),
    ThemeColorRole('onSurface', '表面文字'),
    ThemeColorRole('surfaceContainer', '容器表面'),
    ThemeColorRole('outline', '轮廓线'),
  ];

  static const Set<String> ids = {
    'primary',
    'onPrimary',
    'secondary',
    'onSecondary',
    'tertiary',
    'onTertiary',
    'error',
    'onError',
    'surface',
    'onSurface',
    'surfaceContainer',
    'outline',
    // Jingshiro ThemeStore 别名（导入兼容；bottomBackground 在 buildTheme 单独用于底栏）
    'accent',
    'bottomBackground',
  };

  static String toHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  static Color? fromHex(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    var s = raw.trim();
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 6) s = 'FF$s';
    if (s.length != 8) return null;
    final value = int.tryParse(s, radix: 16);
    if (value == null) return null;
    return Color(value);
  }

  static Map<String, String> colorsToHex(Map<String, Color> colors) {
    return {for (final e in colors.entries) e.key: toHex(e.value)};
  }

  static Map<String, Color> colorsFromHex(Map<String, dynamic>? raw) {
    if (raw == null) return {};
    final out = <String, Color>{};
    for (final entry in raw.entries) {
      if (!ids.contains(entry.key)) continue;
      final color = fromHex(entry.value?.toString());
      if (color != null) out[entry.key] = color;
    }
    return out;
  }

  static ColorScheme applyOverrides(
    ColorScheme base,
    Map<String, Color> overrides,
  ) {
    if (overrides.isEmpty) return base;
    // Jingshiro ThemeStore.accent → MD3 secondary
    // bottomBackground 不覆盖 surface（内容区与底栏需可区分）
    final accent = overrides['accent'] ?? overrides['secondary'];
    return base.copyWith(
      primary: overrides['primary'],
      onPrimary: overrides['onPrimary'],
      secondary: accent,
      onSecondary: overrides['onSecondary'],
      tertiary: overrides['tertiary'],
      onTertiary: overrides['onTertiary'],
      error: overrides['error'],
      onError: overrides['onError'],
      surface: overrides['surface'],
      onSurface: overrides['onSurface'],
      surfaceContainer: overrides['surfaceContainer'],
      outline: overrides['outline'],
    );
  }
}

/// 可导入/导出的主题配置
class LegadoThemeConfig {
  final String version;
  final String? mode;
  final String? preset;
  final Map<String, Color> colors;

  const LegadoThemeConfig({
    this.version = '1',
    this.mode,
    this.preset,
    this.colors = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      if (mode != null) 'mode': mode,
      if (preset != null) 'preset': preset,
      if (colors.isNotEmpty)
        'colors': ThemeColorRoles.colorsToHex(colors),
    };
  }
}
