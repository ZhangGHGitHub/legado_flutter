import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Chrome 尺寸：对齐 Jingshiro / Material `actionBarSize` 思路，
/// 按平台与窗口尺寸自适应，避免全端写死同一逻辑像素。
///
/// Android Material 参考值（dp ≈ Flutter logical px）：
/// - 手机竖屏：56
/// - 手机横屏：48
/// - 平板 sw≥600：64
abstract final class LegadoChrome {
  static bool get isDesktopShell {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  /// 最短边 ≥ 600 视为平板级窗口（对齐 sw600dp）
  static bool isLargeWindow(BuildContext context) {
    return MediaQuery.sizeOf(context).shortestSide >= 600;
  }

  static bool isLandscape(BuildContext context) {
    final s = MediaQuery.sizeOf(context);
    return s.width > s.height;
  }

  /// AppBar — 对齐 Material `?attr/actionBarSize`
  static double toolbarHeightOf(BuildContext context) {
    if (isDesktopShell) {
      // 桌面：窗口常大于 sw600，但鼠标密度更高，取 Material 手机默认，
      // 大窗略增；不用手机横屏的 48，避免标题过挤。
      return isLargeWindow(context) ? 56.0 : 52.0;
    }
    if (isLargeWindow(context)) return 64.0;
    if (isLandscape(context)) return 48.0;
    return 56.0;
  }

  /// 弹窗次级页标题栏 — 与顶栏同套规则（Jingshiro Toolbar wrap_content）
  static double dialogTitleBarHeightOf(BuildContext context) {
    return toolbarHeightOf(context);
  }

  /// 底栏 — 给图标+文字留白；桌面略紧、大屏略松
  static double navigationBarHeightOf(BuildContext context) {
    if (isDesktopShell) return isLargeWindow(context) ? 64.0 : 60.0;
    if (isLargeWindow(context)) return 72.0;
    return 64.0;
  }

  static double selectActionBarHeightOf(BuildContext context) {
    if (isDesktopShell) return 52.0;
    if (isLargeWindow(context)) return 56.0;
    return 52.0;
  }

  static double iconButtonMinOf(BuildContext context) {
    if (isDesktopShell) return 40.0;
    if (isLargeWindow(context)) return 48.0;
    return 44.0;
  }

  static ThemeData applyTo(BuildContext context, ThemeData base) {
    final toolbar = toolbarHeightOf(context);
    final nav = navigationBarHeightOf(context);
    final iconMin = iconButtonMinOf(context);
    return base.copyWith(
      appBarTheme: base.appBarTheme.copyWith(toolbarHeight: toolbar),
      navigationBarTheme: base.navigationBarTheme.copyWith(height: nav),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: Size(iconMin, iconMin),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.standard,
          padding: const EdgeInsets.all(8),
        ),
      ),
    );
  }
}
