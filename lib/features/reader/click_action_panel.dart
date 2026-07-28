import 'package:flutter/material.dart';

import '../../services/click_action_prefs.dart';
import 'reader_settings.dart';

/// 点击区域配置（对齐 dialog_click_action_config：九宫格）
class ClickActionPanel extends StatefulWidget {
  final ReaderSettings settings;
  final ValueChanged<ReaderSettings> onChanged;

  const ClickActionPanel({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required ReaderSettings settings,
    required ValueChanged<ReaderSettings> onChanged,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '关闭',
      barrierColor: Colors.black54,
      pageBuilder: (ctx, animation, secondaryAnimation) =>
          ClickActionPanel(settings: settings, onChanged: onChanged),
    );
  }

  @override
  State<ClickActionPanel> createState() => _ClickActionPanelState();
}

class _ClickActionPanelState extends State<ClickActionPanel> {
  late ReaderSettings _s;

  @override
  void initState() {
    super.initState();
    _s = widget.settings;
  }

  Future<void> _update(ReaderSettings next) async {
    var layout = ClickZoneLayout(
      tl: next.clickTL,
      tc: next.clickTC,
      tr: next.clickTR,
      ml: next.clickML,
      mc: next.clickMC,
      mr: next.clickMR,
      bl: next.clickBL,
      bc: next.clickBC,
      br: next.clickBR,
    );
    if (!layout.hasMenu) {
      layout = layout.copyWith(mc: ClickZoneAction.menu);
      next = next.copyWith(clickMC: ClickZoneAction.menu);
    }
    setState(() => _s = next);
    widget.onChanged(next);
    await ClickActionPrefs.save(layout);
  }

  Future<void> _pickZone({
    required ClickZoneAction current,
    required ReaderSettings Function(ClickZoneAction) apply,
  }) async {
    final chosen = await showModalBottomSheet<ClickZoneAction>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final maxH = MediaQuery.of(ctx).size.height * 0.7;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '选择操作',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final a in ClickZoneAction.selectorOrder)
                        ListTile(
                          dense: true,
                          title: Text(
                            a.label,
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: a == current
                              ? const Icon(Icons.check, size: 18)
                              : null,
                          onTap: () => Navigator.pop(ctx, a),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (chosen != null) {
      await _update(apply(chosen));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(3),
                padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '点击区域设置',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(child: _grid()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _grid() {
    Widget cell(
      ClickZoneAction action,
      ReaderSettings Function(ClickZoneAction) apply,
    ) {
      return Expanded(
        child: GestureDetector(
          onTap: () => _pickZone(current: action, apply: apply),
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
        ),
      );
    }

    Widget row(
      ClickZoneAction left,
      ClickZoneAction center,
      ClickZoneAction right,
      ReaderSettings Function(ClickZoneAction) applyL,
      ReaderSettings Function(ClickZoneAction) applyC,
      ReaderSettings Function(ClickZoneAction) applyR,
    ) {
      return Expanded(
        child: Row(
          children: [
            cell(left, applyL),
            cell(center, applyC),
            cell(right, applyR),
          ],
        ),
      );
    }

    return Column(
      children: [
        row(
          _s.clickTL,
          _s.clickTC,
          _s.clickTR,
          (a) => _s.copyWith(clickTL: a),
          (a) => _s.copyWith(clickTC: a),
          (a) => _s.copyWith(clickTR: a),
        ),
        row(
          _s.clickML,
          _s.clickMC,
          _s.clickMR,
          (a) => _s.copyWith(clickML: a),
          (a) => _s.copyWith(clickMC: a),
          (a) => _s.copyWith(clickMR: a),
        ),
        row(
          _s.clickBL,
          _s.clickBC,
          _s.clickBR,
          (a) => _s.copyWith(clickBL: a),
          (a) => _s.copyWith(clickBC: a),
          (a) => _s.copyWith(clickBR: a),
        ),
      ],
    );
  }
}
