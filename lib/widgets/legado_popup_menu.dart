import 'package:flutter/material.dart';

import '../theme/legado_chrome.dart';

/// AppBar 弹出菜单：顶边贴齐顶栏底边（对齐 Jingshiro Toolbar 下拉）。
/// 搭配默认 [PopupMenuPosition.over] 使用。
Offset legadoAppBarPopupOffset(BuildContext context) {
  final toolbar = LegadoChrome.toolbarHeightOf(context);
  return Offset(0, (toolbar + kMinInteractiveDimension) / 2);
}

/// 底栏「更多」：按底栏顶边定位，菜单整体浮在底栏上方。
Future<T?> showLegadoBottomBarMenu<T>({
  required BuildContext context,
  required GlobalKey barKey,
  BuildContext? buttonContext,
  required List<PopupMenuEntry<T>> items,
  double gapAboveBar = 8,
  double rightPadding = 8,
  double menuWidth = 168,
}) async {
  final barBox = barKey.currentContext?.findRenderObject() as RenderBox?;
  final overlayBox =
      Overlay.of(context).context.findRenderObject() as RenderBox?;
  if (overlayBox == null) return null;

  double barTop;
  if (barBox != null) {
    barTop = barBox.localToGlobal(Offset.zero).dy;
  } else if (buttonContext != null) {
    final buttonBox = buttonContext.findRenderObject() as RenderBox?;
    if (buttonBox == null) return null;
    barTop = buttonBox.localToGlobal(Offset.zero).dy;
  } else {
    return null;
  }

  // PopupMenuItem 默认约 48；再加一点 padding 余量
  final estimatedMenuHeight = 48.0 * items.length + 16.0;
  final menuBottomY = barTop - gapAboveBar;
  final menuTopY = menuBottomY - estimatedMenuHeight;
  final menuLeft = overlayBox.size.width - rightPadding - menuWidth;

  final position = RelativeRect.fromLTRB(
    menuLeft,
    menuTopY.clamp(8.0, overlayBox.size.height),
    rightPadding,
    (overlayBox.size.height - menuBottomY).clamp(0.0, overlayBox.size.height),
  );

  return showMenu<T>(
    context: context,
    position: position,
    items: items,
  );
}

/// 底栏溢出菜单按钮：点击后菜单向上超出底栏弹出。
class LegadoBottomBarPopupButton<T> extends StatelessWidget {
  const LegadoBottomBarPopupButton({
    super.key,
    required this.barKey,
    required this.itemBuilder,
    this.onSelected,
    this.enabled = true,
    this.tooltip = '更多',
    this.icon,
    this.menuWidth = 168,
  });

  final GlobalKey barKey;
  final PopupMenuItemBuilder<T> itemBuilder;
  final ValueChanged<T>? onSelected;
  final bool enabled;
  final String? tooltip;
  final Widget? icon;
  final double menuWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Builder(
      builder: (btnCtx) => IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        icon: icon ??
            Icon(
              Icons.more_vert,
              color: enabled
                  ? scheme.onSurface
                  : scheme.onSurface.withValues(alpha: 0.38),
              size: 22,
            ),
        onPressed: !enabled
            ? null
            : () async {
                final value = await showLegadoBottomBarMenu<T>(
                  context: context,
                  barKey: barKey,
                  buttonContext: btnCtx,
                  menuWidth: menuWidth,
                  items: itemBuilder(context),
                );
                if (value != null && onSelected != null) {
                  onSelected!(value);
                }
              },
      ),
    );
  }
}
