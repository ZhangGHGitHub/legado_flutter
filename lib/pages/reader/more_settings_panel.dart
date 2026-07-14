import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'reader_settings.dart';

/// 阅读器「更多设置」（UI-2）：
/// 屏幕方向 / 超时分档 / 状态栏·导航栏沉浸 / 刘海 / 亮度 / 蓝牙翻页器 / 自定义翻页键。
class MoreSettingsPanel extends StatefulWidget {
  final ReaderSettings settings;
  final ValueChanged<ReaderSettings> onChanged;

  const MoreSettingsPanel({
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
      builder: (_) => MoreSettingsPanel(
        settings: settings,
        onChanged: onChanged,
      ),
    );
  }

  @override
  State<MoreSettingsPanel> createState() => _MoreSettingsPanelState();
}

class _MoreSettingsPanelState extends State<MoreSettingsPanel> {
  late ReaderSettings _s;
  String? _capturing; // 'prev' | 'next'

  @override
  void initState() {
    super.initState();
    _s = widget.settings;
  }

  void _update(ReaderSettings s) {
    setState(() => _s = s);
    widget.onChanged(s);
  }

  String _keyLabel(String? keyId) {
    if (keyId == null || keyId.isEmpty) return '未设置';
    for (final k in LogicalKeyboardKey.knownLogicalKeys) {
      if (k.keyId.toString() == keyId || k.debugName == keyId) {
        return k.keyLabel.isNotEmpty ? k.keyLabel : (k.debugName ?? keyId);
      }
    }
    return keyId;
  }

  KeyEventResult _onCapture(FocusNode node, KeyEvent event) {
    if (_capturing == null) return KeyEventResult.ignored;
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final id = event.logicalKey.keyId.toString();
    if (_capturing == 'prev') {
      _update(_s.copyWith(customPrevPageKey: id));
    } else {
      _update(_s.copyWith(customNextPageKey: id));
    }
    setState(() => _capturing = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已绑定：${_keyLabel(id)}'),
        duration: const Duration(seconds: 2),
      ),
    );
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: _capturing != null,
      onKeyEvent: _onCapture,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 12,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                  child: Row(
                    children: [
                      const Text(
                        '更多设置',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
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
                    '屏幕方向 · 超时 · 沉浸栏 · 亮度 · 翻页键',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(),

                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Text('屏幕方向', style: TextStyle(fontSize: 13)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (final m in ScreenOrientationMode.values)
                        ChoiceChip(
                          label: Text(m.label, style: const TextStyle(fontSize: 12)),
                          selected: _s.screenOrientation == m,
                          onSelected: (_) =>
                              _update(_s.copyWith(screenOrientation: m)),
                        ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text('屏幕超时', style: TextStyle(fontSize: 13)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final m in ScreenTimeoutMode.values)
                        ChoiceChip(
                          label: Text(m.label, style: const TextStyle(fontSize: 12)),
                          selected: _s.screenTimeout == m,
                          onSelected: (_) =>
                              _update(_s.copyWith(screenTimeout: m)),
                        ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(
                    '对齐 keepLight：默认跟随系统；1/5/10 分钟内保持亮屏；常亮始终唤醒',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),

                const Divider(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Text('状态栏 / 刘海', style: TextStyle(fontSize: 13)),
                ),
                SwitchListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: const Text('隐藏状态栏', style: TextStyle(fontSize: 13)),
                  subtitle: const Text(
                    '阅读界面隐藏状态栏；菜单唤起时短暂显示',
                    style: TextStyle(fontSize: 11),
                  ),
                  value: _s.hideStatusBar,
                  onChanged: (v) => _update(_s.copyWith(hideStatusBar: v)),
                ),
                SwitchListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: const Text('隐藏导航栏', style: TextStyle(fontSize: 13)),
                  subtitle: const Text(
                    '阅读界面隐藏虚拟导航键',
                    style: TextStyle(fontSize: 11),
                  ),
                  value: _s.hideNavigationBar,
                  onChanged: (v) =>
                      _update(_s.copyWith(hideNavigationBar: v)),
                ),
                SwitchListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: const Text('扩展到刘海', style: TextStyle(fontSize: 13)),
                  subtitle: const Text(
                    '正文贴边绘制（对齐 readBodyToLh）',
                    style: TextStyle(fontSize: 11),
                  ),
                  value: _s.expandIntoCutout,
                  onChanged: (v) =>
                      _update(_s.copyWith(expandIntoCutout: v)),
                ),
                SwitchListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: const Text('文字两端对齐', style: TextStyle(fontSize: 13)),
                  value: _s.textFullJustify,
                  onChanged: (v) =>
                      _update(_s.copyWith(textFullJustify: v)),
                ),
                SwitchListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: const Text('文字底部对齐', style: TextStyle(fontSize: 13)),
                  subtitle: const Text(
                    '分页模式下不足一页时正文贴底（对齐 textBottomJustify）',
                    style: TextStyle(fontSize: 11),
                  ),
                  value: _s.textBottomJustify,
                  onChanged: (v) =>
                      _update(_s.copyWith(textBottomJustify: v)),
                ),

                const Divider(),
                SwitchListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: const Text('亮度跟随系统', style: TextStyle(fontSize: 13)),
                  value: _s.brightnessFollowSystem,
                  onChanged: (v) =>
                      _update(_s.copyWith(brightnessFollowSystem: v)),
                ),
                if (!_s.brightnessFollowSystem)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.brightness_6_outlined, size: 20),
                        Expanded(
                          child: Slider(
                            value: _s.brightness.clamp(0.15, 1.0),
                            min: 0.15,
                            max: 1.0,
                            divisions: 17,
                            label: (_s.brightness * 100).round().toString(),
                            onChanged: (v) =>
                                _update(_s.copyWith(brightness: v)),
                          ),
                        ),
                        Text(
                          '${(_s.brightness * 100).round()}%',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                const Divider(),
                SwitchListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: const Text('蓝牙翻页器', style: TextStyle(fontSize: 13)),
                  subtitle: const Text(
                    '响应 PageUp/PageDown 与媒体上一曲/下一曲',
                    style: TextStyle(fontSize: 11),
                  ),
                  value: _s.bluetoothPageKey,
                  onChanged: (v) => _update(_s.copyWith(bluetoothPageKey: v)),
                ),
                SwitchListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: const Text('音量键翻页', style: TextStyle(fontSize: 13)),
                  value: _s.volumeKeyTurnPage,
                  onChanged: (v) =>
                      _update(_s.copyWith(volumeKeyTurnPage: v)),
                ),
                SwitchListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: const Text('朗读时音量键翻页', style: TextStyle(fontSize: 13)),
                  subtitle: const Text(
                    '关闭后朗读中音量键调音量',
                    style: TextStyle(fontSize: 11),
                  ),
                  value: _s.volumeKeyPageOnPlay,
                  onChanged: (v) =>
                      _update(_s.copyWith(volumeKeyPageOnPlay: v)),
                ),
                ListTile(
                  dense: true,
                  title: const Text('自定义上一页键', style: TextStyle(fontSize: 13)),
                  subtitle: Text(
                    _capturing == 'prev'
                        ? '请按下键盘按键…'
                        : _keyLabel(_s.customPrevPageKey),
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: TextButton(
                    onPressed: () => setState(() => _capturing = 'prev'),
                    child: Text(_capturing == 'prev' ? '等待中' : '设置'),
                  ),
                ),
                ListTile(
                  dense: true,
                  title: const Text('自定义下一页键', style: TextStyle(fontSize: 13)),
                  subtitle: Text(
                    _capturing == 'next'
                        ? '请按下键盘按键…'
                        : _keyLabel(_s.customNextPageKey),
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: TextButton(
                    onPressed: () => setState(() => _capturing = 'next'),
                    child: Text(_capturing == 'next' ? '等待中' : '设置'),
                  ),
                ),
                if (_s.customPrevPageKey != null ||
                    _s.customNextPageKey != null)
                  TextButton(
                    onPressed: () => _update(
                      _s.copyWith(
                        clearCustomPrevPageKey: true,
                        clearCustomNextPageKey: true,
                      ),
                    ),
                    child: const Text('清除自定义翻页键'),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
