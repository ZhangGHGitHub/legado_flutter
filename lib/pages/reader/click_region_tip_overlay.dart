import 'package:flutter/material.dart';

import '../../models/click_zone.dart';

/// 首次进入阅读页的点击区域提示（九宫格标签，轻触关闭）
class ClickRegionTipOverlay extends StatelessWidget {
  final ClickZoneLayout layout;
  final VoidCallback onDismiss;

  const ClickRegionTipOverlay({
    super.key,
    required this.layout,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onDismiss,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(3),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Text(
                          '点击区域设置',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(Icons.close, color: Colors.white, size: 22),
                    ],
                  ),
                ),
                Expanded(child: _grid()),
                const Padding(
                  padding: EdgeInsets.only(bottom: 12, top: 4),
                  child: Text(
                    '轻触任意位置关闭',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _grid() {
    Widget cell(ClickZoneAction action) {
      return Expanded(
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            action.label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      );
    }

    Widget row(ClickZoneAction l, ClickZoneAction c, ClickZoneAction r) {
      return Expanded(
        child: Row(children: [cell(l), cell(c), cell(r)]),
      );
    }

    return Column(
      children: [
        row(layout.tl, layout.tc, layout.tr),
        row(layout.ml, layout.mc, layout.mr),
        row(layout.bl, layout.bc, layout.br),
      ],
    );
  }
}
