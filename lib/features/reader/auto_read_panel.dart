import 'package:flutter/material.dart';

import 'reader_settings.dart';

/// 自动阅读设置（对齐 dialog_auto_read：定时翻页速度）
class AutoReadPanel extends StatefulWidget {
  final ReaderSettings settings;
  final bool isRunning;
  final ValueChanged<ReaderSettings> onChanged;
  final ValueChanged<bool> onRunningChanged;

  const AutoReadPanel({
    super.key,
    required this.settings,
    required this.isRunning,
    required this.onChanged,
    required this.onRunningChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required ReaderSettings settings,
    required bool isRunning,
    required ValueChanged<ReaderSettings> onChanged,
    required ValueChanged<bool> onRunningChanged,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => AutoReadPanel(
        settings: settings,
        isRunning: isRunning,
        onChanged: onChanged,
        onRunningChanged: onRunningChanged,
      ),
    );
  }

  @override
  State<AutoReadPanel> createState() => _AutoReadPanelState();
}

class _AutoReadPanelState extends State<AutoReadPanel> {
  late ReaderSettings _s;
  late bool _running;

  @override
  void initState() {
    super.initState();
    _s = widget.settings;
    _running = widget.isRunning;
  }

  void _applyInterval(double v) {
    final next = _s.copyWith(autoReadIntervalSec: v);
    setState(() => _s = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final interval = _s.autoReadIntervalSec;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  const Text(
                    '自动阅读',
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
                '按设定间隔自动翻页；滚动模式按章切换',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('翻页间隔', style: TextStyle(fontSize: 13)),
                  Expanded(
                    child: Slider(
                      value: interval.clamp(1.5, 20),
                      min: 1.5,
                      max: 20,
                      divisions: 37,
                      label: '${interval.toStringAsFixed(1)}s',
                      onChanged: _applyInterval,
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text(
                      '${interval.toStringAsFixed(1)}s',
                      style: const TextStyle(fontSize: 13),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
            SwitchListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(
                _running ? '正在自动翻页' : '开始自动阅读',
                style: const TextStyle(fontSize: 13),
              ),
              subtitle: Text(
                _running ? '关闭开关即可停止' : '开启后按间隔翻页',
                style: const TextStyle(fontSize: 11),
              ),
              value: _running,
              onChanged: (v) {
                setState(() => _running = v);
                widget.onRunningChanged(v);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
