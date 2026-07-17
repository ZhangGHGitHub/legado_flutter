import 'package:flutter/material.dart';

import '../services/reader_font_loader.dart';
import '../theme/legado_chrome.dart';

/// 主壳底栏一项
class LegadoBottomNavItem {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final Widget? badge;

  const LegadoBottomNavItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.badge,
  });
}

/// 对齐 Jingshiro [ThemeBottomNavigationVIew]：
/// 选中时图标上移 + 文字变色；图标/字号随 [height] 相对基准缩放。
class LegadoBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<LegadoBottomNavItem> destinations;
  final double height;

  const LegadoBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.height = 64,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = theme.navigationBarTheme;
    final scheme = theme.colorScheme;
    final bg = nav.backgroundColor ?? scheme.surface;
    final accent = scheme.secondary;
    final unselected = theme.brightness == Brightness.light
        ? const Color(0x8A000000)
        : scheme.onSurfaceVariant;
    final uiFont = ReaderFontLoader.platformSansFamily();
    final uiFallback = ReaderFontLoader.cjkFallbackFamilies();
    final scale = height / LegadoChrome.navigationBarHeightBase;
    final iconSize = LegadoChrome.navIconSizeBase * scale;
    final labelSize = LegadoChrome.navLabelFontBase * scale;
    final vPad = (8.0 * scale).clamp(6.0, 16.0);
    // 上移幅度不跟高度同比放大，避免 Windows 大底栏选中后明显「飘」偏
    final iconLift = (5.0 * scale).clamp(4.0, 6.0);
    final gap = (4.0 * scale).clamp(2.0, 8.0);

    return Material(
      elevation: nav.elevation ?? 2,
      color: bg,
      shadowColor: nav.shadowColor ?? Colors.black26,
      surfaceTintColor: Colors.transparent,
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            for (var i = 0; i < destinations.length; i++)
              Expanded(
                child: _LegadoBottomNavTile(
                  item: destinations[i],
                  selected: i == selectedIndex,
                  accent: accent,
                  unselected: unselected,
                  fontFamily: uiFont,
                  fontFallback: uiFallback,
                  iconSize: iconSize,
                  labelSize: labelSize,
                  verticalPadding: vPad,
                  iconLift: iconLift,
                  iconLabelGap: gap,
                  onTap: () => onDestinationSelected(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LegadoBottomNavTile extends StatelessWidget {
  final LegadoBottomNavItem item;
  final bool selected;
  final Color accent;
  final Color unselected;
  final String fontFamily;
  final List<String> fontFallback;
  final double iconSize;
  final double labelSize;
  final double verticalPadding;
  final double iconLift;
  final double iconLabelGap;
  final VoidCallback onTap;

  const _LegadoBottomNavTile({
    required this.item,
    required this.selected,
    required this.accent,
    required this.unselected,
    required this.fontFamily,
    required this.fontFallback,
    required this.iconSize,
    required this.labelSize,
    required this.verticalPadding,
    required this.iconLift,
    required this.iconLabelGap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? accent : unselected;
    final iconData =
        selected ? (item.selectedIcon ?? item.icon) : item.icon;

    // 选中只变色 + 轻微上移；不做 scale / AnimatedSwitcher，避免点击后图标视觉偏移
    final lift = selected ? iconLift : 0.0;

    return InkWell(
      onTap: onTap,
      splashColor: accent.withValues(alpha: 0.10),
      highlightColor: accent.withValues(alpha: 0.06),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Transform.translate(
              offset: Offset(0, -lift),
              child: SizedBox(
                width: iconSize,
                height: iconSize,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      iconData,
                      size: iconSize,
                      color: color,
                    ),
                    if (item.badge != null)
                      Positioned(
                        right: -10 * (iconSize / 24),
                        top: -6 * (iconSize / 24),
                        child: item.badge!,
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: iconLabelGap),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: labelSize,
                height: 1.2,
                fontWeight: FontWeight.w400,
                color: color,
                fontFamily: fontFamily,
                fontFamilyFallback: fontFallback,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
