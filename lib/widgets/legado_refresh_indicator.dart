import 'package:flutter/material.dart';

/// 书架下拉刷新 — 对齐 Jingshiro `SwipeRefreshLayout` + `BooksFragment` 行为：
/// - 指示器使用主题 accent（`setColorSchemeColors(accentColor)`）
/// - 松手后立刻结束转圈（`isRefreshing = false`），实际目录更新在后台进行
class LegadoRefreshIndicator extends StatelessWidget {
  const LegadoRefreshIndicator({
    super.key,
    required this.onRefreshTriggered,
    required this.child,
    this.enabled = true,
    this.displacement = 40,
  });

  /// 触发后台刷新（勿 await 长任务；与 legado `upToc` 一致）
  final VoidCallback onRefreshTriggered;

  final Widget child;
  final bool enabled;
  final double displacement;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final scheme = Theme.of(context).colorScheme;
    return RefreshIndicator(
      color: scheme.primary,
      backgroundColor: scheme.surface,
      displacement: displacement,
      strokeWidth: 2.5,
      onRefresh: () async {
        onRefreshTriggered();
        // legado 在 listener 内立即 `isRefreshing = false`；留极短反馈避免闪断
        await Future<void>.delayed(const Duration(milliseconds: 120));
      },
      child: child,
    );
  }
}

/// 列表/网格 overscroll 光晕 — 对齐 `FastScrollRecyclerView.setEdgeEffectColor(primaryColor)`
class LegadoScrollBehavior extends ScrollBehavior {
  const LegadoScrollBehavior({this.overscrollColor});

  final Color? overscrollColor;

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    final color = overscrollColor ?? Theme.of(context).colorScheme.primary;
    return GlowingOverscrollIndicator(
      axisDirection: details.direction,
      color: color,
      child: child,
    );
  }
}

/// 书架项右侧更新中动画 — 对齐 `RotateLoading`（26dp / 2dp / accent）
class LegadoShelfUpdatingIndicator extends StatelessWidget {
  const LegadoShelfUpdatingIndicator({super.key, this.size = 26});

  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: color,
      ),
    );
  }
}
