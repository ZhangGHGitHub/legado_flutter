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
  /// 顶栏 / 底栏文字与图标的设计基准（缩放分母）
  static const double toolbarHeightBase = 56.0;
  static const double navigationBarHeightBase = 64.0;
  static const double appBarTitleFontBase = 20.0;
  static const double appBarIconSizeBase = 24.0;
  static const double navIconSizeBase = 24.0;
  static const double navLabelFontBase = 12.0;

  /// 桌面端：窗口宽度越大 → Toolbar/Nav 越高，避免在大屏上感觉过小。
  /// 800dp → 1.0（手机密度），1920dp → 1.5
  static double _desktopScale(double width) {
    const minW = 800.0;
    const maxW = 1920.0;
    if (width <= minW) return 1.0;
    if (width >= maxW) return 1.5;
    return 1.0 + (width - minW) / (maxW - minW) * 0.5;
  }

  /// 桌面端字体/图标缩放（比高度缩放更保守）。
  /// 高度 1.5× 时字体仅 1.25×
  static double _desktopFontScale(double width) {
    final h = _desktopScale(width);
    return 1.0 + (h - 1.0) * 0.5;
  }

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

  static bool _isLandscape(BuildContext context) {
    final s = MediaQuery.sizeOf(context);
    return s.width > s.height;
  }

  /// AppBar — 桌面端按窗口宽度线性缩放，移动端按 Material 惯例
  static double toolbarHeightOf(BuildContext context) {
    if (isDesktopShell) {
      return toolbarHeightBase * _desktopScale(MediaQuery.sizeOf(context).width);
    }
    if (isLargeWindow(context)) return 64.0;
    if (_isLandscape(context)) return 48.0;
    return 56.0;
  }

  /// 弹窗次级页标题栏 — 与顶栏同套规则（Jingshiro Toolbar wrap_content）
  static double dialogTitleBarHeightOf(BuildContext context) {
    return toolbarHeightOf(context);
  }

  /// 底栏 — 桌面端按窗口宽度线性缩放
  static double navigationBarHeightOf(BuildContext context) {
    if (isDesktopShell) {
      return navigationBarHeightBase *
          _desktopFontScale(MediaQuery.sizeOf(context).width);
    }
    if (isLargeWindow(context)) return 72.0;
    return 64.0;
  }

  static double selectActionBarHeightOf(BuildContext context) {
    if (isDesktopShell) {
      return 52.0 * _desktopScale(MediaQuery.sizeOf(context).width);
    }
    if (isLargeWindow(context)) return 56.0;
    return 52.0;
  }

  /// 顶栏相对基准的缩放（文字/图标随高度同比）
  static double toolbarScaleOf(BuildContext context) {
    return toolbarHeightOf(context) / toolbarHeightBase;
  }

  /// 底栏相对基准的缩放
  static double navigationScaleOf(BuildContext context) {
    return navigationBarHeightOf(context) / navigationBarHeightBase;
  }

  static double appBarTitleFontOf(BuildContext context) {
    if (isDesktopShell) {
      return appBarTitleFontBase * _desktopFontScale(MediaQuery.sizeOf(context).width);
    }
    return appBarTitleFontBase * toolbarScaleOf(context);
  }

  static double appBarIconSizeOf(BuildContext context) {
    if (isDesktopShell) {
      return appBarIconSizeBase * _desktopFontScale(MediaQuery.sizeOf(context).width);
    }
    return appBarIconSizeBase * toolbarScaleOf(context);
  }

  static double navIconSizeOf(BuildContext context) {
    if (isDesktopShell) {
      return navIconSizeBase * _desktopFontScale(MediaQuery.sizeOf(context).width);
    }
    return navIconSizeBase * navigationScaleOf(context);
  }

  static double navLabelFontOf(BuildContext context) {
    if (isDesktopShell) {
      return navLabelFontBase * _desktopFontScale(MediaQuery.sizeOf(context).width);
    }
    return navLabelFontBase * navigationScaleOf(context);
  }

  /// 顶栏标题起始内边距（分组「全部」略右移）
  static double appBarTitleStartPaddingOf(BuildContext context) {
    if (isDesktopShell) {
      return 12.0 * _desktopFontScale(MediaQuery.sizeOf(context).width);
    }
    return 12.0;
  }

  static double iconButtonMinOf(BuildContext context) {
    if (isDesktopShell) {
      return 40.0 * _desktopFontScale(MediaQuery.sizeOf(context).width);
    }
    if (isLargeWindow(context)) return 48.0;
    return 44.0;
  }

  static ThemeData applyTo(BuildContext context, ThemeData base) {
    final toolbar = toolbarHeightOf(context);
    final nav = navigationBarHeightOf(context);
    final iconMin = iconButtonMinOf(context);
    final titleSize = appBarTitleFontOf(context);
    final barIcon = appBarIconSizeOf(context);
    final navIcon = navIconSizeOf(context);
    final navLabel = navLabelFontOf(context);
    final onBar = base.appBarTheme.foregroundColor ??
        base.colorScheme.onPrimary;
    final titleStyle = (base.appBarTheme.titleTextStyle ??
            base.textTheme.titleLarge ??
            const TextStyle())
        .copyWith(
          fontSize: titleSize,
          color: onBar,
          fontWeight: FontWeight.w400,
        );

    return base.copyWith(
      appBarTheme: base.appBarTheme.copyWith(
        toolbarHeight: toolbar,
        titleTextStyle: titleStyle,
        iconTheme: (base.appBarTheme.iconTheme ?? const IconThemeData())
            .copyWith(size: barIcon, color: onBar),
        actionsIconTheme:
            (base.appBarTheme.actionsIconTheme ?? const IconThemeData())
                .copyWith(size: barIcon, color: onBar),
        titleSpacing: appBarTitleStartPaddingOf(context),
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        height: nav,
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(size: navIcon),
        ),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: navLabel,
            height: 1.2,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: Size(iconMin, iconMin),
          iconSize: barIcon,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.standard,
          padding: EdgeInsets.all(8 * toolbarScaleOf(context).clamp(1.0, 1.5)),
        ),
      ),
    );
  }
}
