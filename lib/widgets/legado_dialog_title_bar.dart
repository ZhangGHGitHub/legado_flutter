import 'package:flutter/material.dart';

import '../theme/legado_chrome.dart';
import '../theme/legado_tokens.dart';

/// 弹窗次级页顶栏 — 对齐 Jingshiro Dialog MaterialToolbar：
/// 主色底、圆角顶边、标题偏左、右侧可选操作；
/// 高度跟 [LegadoChrome.dialogTitleBarHeightOf]（非写死）。
class LegadoDialogTitleBar extends StatelessWidget {
  const LegadoDialogTitleBar({
    super.key,
    required this.title,
    this.actions = const [],
  });

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onBar = scheme.onPrimary;

    return Material(
      color: scheme.primary,
      child: SizedBox(
        height: LegadoChrome.dialogTitleBarHeightOf(context),
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: onBar,
                    fontSize: LegadoChrome.appBarTitleFontOf(context),
                    fontWeight: FontWeight.w400,
                    height: 1.25,
                  ),
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }

  /// 供 Dialog `shape` 使用
  static ShapeBorder dialogShape({double? radius}) {
    final r = radius ?? LegadoTokens.dialogRadius;
    return RoundedRectangleBorder(borderRadius: BorderRadius.circular(r));
  }
}
