import 'package:flutter/material.dart';

/// 应用 MD3 配色预设（Phase 2.6）
enum LegadoColorPreset {
  light,
  dark,
  eyeCare,
  paper,
  night,
  dynamic,
}

/// 预设元数据
class LegadoColorPresetInfo {
  final LegadoColorPreset id;
  final String label;
  final String description;
  final Color preview;
  final Color seedColor;

  const LegadoColorPresetInfo({
    required this.id,
    required this.label,
    required this.description,
    required this.preview,
    required this.seedColor,
  });
}

abstract final class LegadoColorPresets {
  static const _lightSeed = Color(0xFF2196F3);
  static const _darkSeed = Color(0xFF5C6BC0);
  static const _eyeCareSeed = Color(0xFF43A047);
  static const _paperSeed = Color(0xFF8D6E63);
  static const _nightSeed = Color(0xFFFFB74D);

  static const List<LegadoColorPresetInfo> all = [
    LegadoColorPresetInfo(
      id: LegadoColorPreset.light,
      label: '浅色',
      description: '经典蓝色 MD3',
      preview: Color(0xFFE3F2FD),
      seedColor: _lightSeed,
    ),
    LegadoColorPresetInfo(
      id: LegadoColorPreset.dark,
      label: '深色',
      description: '靛蓝高对比暗色',
      preview: Color(0xFF1A237E),
      seedColor: _darkSeed,
    ),
    LegadoColorPresetInfo(
      id: LegadoColorPreset.eyeCare,
      label: '护眼',
      description: '柔和绿色护眼',
      preview: Color(0xFFC8E6C9),
      seedColor: _eyeCareSeed,
    ),
    LegadoColorPresetInfo(
      id: LegadoColorPreset.paper,
      label: '纸质',
      description: '暖棕纸质风格',
      preview: Color(0xFFF5F0E8),
      seedColor: _paperSeed,
    ),
    LegadoColorPresetInfo(
      id: LegadoColorPreset.night,
      label: '夜间',
      description: '低蓝光琥珀暗色',
      preview: Color(0xFF1C1B1A),
      seedColor: _nightSeed,
    ),
    LegadoColorPresetInfo(
      id: LegadoColorPreset.dynamic,
      label: '动态取色',
      description: '跟随系统壁纸色彩',
      preview: Color(0xFF7E57C2),
      seedColor: Color(0xFF6750A4),
    ),
  ];

  static LegadoColorPresetInfo infoFor(LegadoColorPreset preset) {
    return all.firstWhere((p) => p.id == preset);
  }

  static LegadoColorPreset parse(String? raw) {
    return LegadoColorPreset.values.firstWhere(
      (p) => p.name == raw,
      orElse: () => LegadoColorPreset.light,
    );
  }

  /// 构建指定预设与明暗的 ColorScheme（dynamic 预设在无系统色时回退浅色）
  static ColorScheme schemeFor(
    LegadoColorPreset preset,
    Brightness brightness, {
    ColorScheme? dynamicLight,
    ColorScheme? dynamicDark,
  }) {
    if (preset == LegadoColorPreset.dynamic) {
      final dynamic = brightness == Brightness.dark ? dynamicDark : dynamicLight;
      if (dynamic != null) return dynamic;
      return ColorScheme.fromSeed(
        seedColor: _lightSeed,
        brightness: brightness,
      );
    }

    return switch (preset) {
      LegadoColorPreset.light => _lightScheme(brightness),
      LegadoColorPreset.dark => _darkScheme(brightness),
      LegadoColorPreset.eyeCare => _eyeCareScheme(brightness),
      LegadoColorPreset.paper => _paperScheme(brightness),
      LegadoColorPreset.night => _nightScheme(brightness),
      LegadoColorPreset.dynamic => ColorScheme.fromSeed(
          seedColor: _lightSeed,
          brightness: brightness,
        ),
    };
  }

  static ColorScheme _lightScheme(Brightness brightness) {
    final base = ColorScheme.fromSeed(
      seedColor: _lightSeed,
      brightness: brightness,
    );
    if (brightness == Brightness.dark) return base;
    // 主色顶栏 / 强调色底栏选中分离（对齐 Jingshiro primary + accent）
    return base.copyWith(
      primary: const Color(0xFF1976D2),
      onPrimary: Colors.white,
      secondary: const Color(0xFFE53935),
      onSecondary: Colors.white,
    );
  }

  static ColorScheme _darkScheme(Brightness brightness) {
    final base = ColorScheme.fromSeed(
      seedColor: _darkSeed,
      brightness: brightness,
    );
    if (brightness == Brightness.light) return base;
    return base.copyWith(
      surface: const Color(0xFF12131A),
      surfaceContainerLow: const Color(0xFF1C1D26),
      surfaceContainer: const Color(0xFF252632),
    );
  }

  static ColorScheme _eyeCareScheme(Brightness brightness) {
    final base = ColorScheme.fromSeed(
      seedColor: _eyeCareSeed,
      brightness: brightness,
    );
    if (brightness == Brightness.dark) {
      return base.copyWith(
        surface: const Color(0xFF1A2E1F),
        surfaceContainerLow: const Color(0xFF243528),
      );
    }
    return base.copyWith(
      surface: const Color(0xFFE8F5E9),
      surfaceContainerLow: const Color(0xFFF1F8E9),
      surfaceContainer: const Color(0xFFDCEDC8),
    );
  }

  static ColorScheme _paperScheme(Brightness brightness) {
    final base = ColorScheme.fromSeed(
      seedColor: _paperSeed,
      brightness: brightness,
    );
    if (brightness == Brightness.dark) {
      return base.copyWith(
        surface: const Color(0xFF2C2824),
        surfaceContainerLow: const Color(0xFF3A3530),
        // 强调色与主色分离（对齐 Jingshiro primary/accent）
        secondary: const Color(0xFFE57373),
        onSecondary: const Color(0xFF3E2723),
      );
    }
    return base.copyWith(
      // 主色：暖棕顶栏（接近截图）
      primary: const Color(0xFF6D4C41),
      onPrimary: Colors.white,
      // 强调色：底栏选中 / Switch（截图红）
      secondary: const Color(0xFFE53935),
      onSecondary: Colors.white,
      surface: const Color(0xFFF5F0E8),
      surfaceContainerLow: const Color(0xFFFAF6F0),
      surfaceContainer: const Color(0xFFEDE4D8),
      onSurface: const Color(0xFF3E3228),
    );
  }

  static ColorScheme _nightScheme(Brightness brightness) {
    final base = ColorScheme.fromSeed(
      seedColor: _nightSeed,
      brightness: brightness,
    );
    if (brightness == Brightness.dark) {
      return base.copyWith(
        surface: const Color(0xFF0F0E0D),
        surfaceContainerLow: const Color(0xFF1A1917),
        surfaceContainer: const Color(0xFF242220),
        primary: const Color(0xFFFFB74D),
        onPrimary: const Color(0xFF3E2723),
      );
    }
    return base.copyWith(
      surface: const Color(0xFFFFF3E0),
      surfaceContainerLow: const Color(0xFFFFECB3),
    );
  }

  /// 导出当前主题配置 JSON 片段
  static Map<String, String> exportConfig({
    required String mode,
    required LegadoColorPreset preset,
  }) {
    final info = infoFor(preset);
    return {
      'version': '1',
      'mode': mode,
      'preset': preset.name,
      'label': info.label,
      'seed': '#${info.seedColor.toARGB32().toRadixString(16).substring(2)}',
    };
  }
}