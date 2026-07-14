import 'package:flutter/material.dart';

import 'reader_settings.dart';

/// 点击区域配置（对齐 dialog_click_action_config：上/中/下）
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
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ClickActionPanel(
        settings: settings,
        onChanged: onChanged,
      ),
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

  void _update(ReaderSettings next) {
    setState(() => _s = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  const Text(
                    '点击区域',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '上 / 中 / 下三区各自行为（对齐 dialog_click_action_config）',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
            _zonePreview(),
            const Divider(),
            _zoneRow(
              label: '上区',
              value: _s.clickTop,
              onPick: (a) => _update(_s.copyWith(clickTop: a)),
            ),
            _zoneRow(
              label: '中区',
              value: _s.clickMiddle,
              onPick: (a) => _update(_s.copyWith(clickMiddle: a)),
            ),
            _zoneRow(
              label: '下区',
              value: _s.clickBottom,
              onPick: (a) => _update(_s.copyWith(clickBottom: a)),
            ),
            TextButton(
              onPressed: () => _update(
                _s.copyWith(
                  clickTop: ClickZoneAction.prevPage,
                  clickMiddle: ClickZoneAction.toggleMenu,
                  clickBottom: ClickZoneAction.nextPage,
                ),
              ),
              child: const Text('恢复默认（上=上一页 · 中=菜单 · 下=下一页）'),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _zonePreview() {
    Color band(ClickZoneAction a) {
      switch (a) {
        case ClickZoneAction.prevPage:
          return Colors.blue.withValues(alpha: 0.15);
        case ClickZoneAction.nextPage:
          return Colors.green.withValues(alpha: 0.15);
        case ClickZoneAction.toggleMenu:
          return Colors.orange.withValues(alpha: 0.15);
        case ClickZoneAction.none:
          return Colors.grey.withValues(alpha: 0.08);
      }
    }

    Widget cell(String title, ClickZoneAction a) {
      return Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: band(a),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
          ),
          alignment: Alignment.center,
          child: Text(
            '$title · ${a.label}',
            style: const TextStyle(fontSize: 13),
          ),
        ),
      );
    }

    return SizedBox(
      height: 160,
      child: Column(
        children: [
          cell('上', _s.clickTop),
          cell('中', _s.clickMiddle),
          cell('下', _s.clickBottom),
        ],
      ),
    );
  }

  Widget _zoneRow({
    required String label,
    required ClickZoneAction value,
    required ValueChanged<ClickZoneAction> onPick,
  }) {
    return ListTile(
      dense: true,
      title: Text(label, style: const TextStyle(fontSize: 13)),
      trailing: DropdownButton<ClickZoneAction>(
        value: value,
        underline: const SizedBox.shrink(),
        items: ClickZoneAction.values
            .map(
              (a) => DropdownMenuItem(
                value: a,
                child: Text(a.label, style: const TextStyle(fontSize: 13)),
              ),
            )
            .toList(),
        onChanged: (a) {
          if (a != null) onPick(a);
        },
      ),
    );
  }
}
