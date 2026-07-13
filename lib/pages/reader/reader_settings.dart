import 'package:flutter/material.dart';

/// 阅读器设置 — Phase F UI-2（对齐 dialog_read_bg_text / dialog_read_book_style 可落地项）
class ReaderSettings {
  final double fontSize;
  final double lineHeight;
  final String themeName; // 'paper' | 'white' | 'dark' | 'green'
  final String pageMode; // 'slide' | 'scroll'
  /// 空串 = 系统默认；其余为内置字体族名
  final String fontFamily;
  final double paddingHorizontal;
  final double paddingVertical;
  final bool showTime;
  final bool showBattery;
  final bool showPageInfo;
  final bool volumeKeyTurnPage;

  const ReaderSettings({
    this.fontSize = 18.0,
    this.lineHeight = 1.8,
    this.themeName = 'paper',
    this.pageMode = 'slide',
    this.fontFamily = '',
    this.paddingHorizontal = 20.0,
    this.paddingVertical = 8.0,
    this.showTime = true,
    this.showBattery = false,
    this.showPageInfo = true,
    this.volumeKeyTurnPage = false,
  });

  ReaderSettings copyWith({
    double? fontSize,
    double? lineHeight,
    String? themeName,
    String? pageMode,
    String? fontFamily,
    double? paddingHorizontal,
    double? paddingVertical,
    bool? showTime,
    bool? showBattery,
    bool? showPageInfo,
    bool? volumeKeyTurnPage,
  }) {
    return ReaderSettings(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      themeName: themeName ?? this.themeName,
      pageMode: pageMode ?? this.pageMode,
      fontFamily: fontFamily ?? this.fontFamily,
      paddingHorizontal: paddingHorizontal ?? this.paddingHorizontal,
      paddingVertical: paddingVertical ?? this.paddingVertical,
      showTime: showTime ?? this.showTime,
      showBattery: showBattery ?? this.showBattery,
      showPageInfo: showPageInfo ?? this.showPageInfo,
      volumeKeyTurnPage: volumeKeyTurnPage ?? this.volumeKeyTurnPage,
    );
  }

  String get fontLabel {
    switch (fontFamily) {
      case 'serif':
        return '衬线';
      case 'monospace':
        return '等宽';
      case '':
        return '系统默认';
      default:
        return fontFamily;
    }
  }
}

/// 阅读主题预设
class ReaderTheme {
  final Color background;
  final Color text;
  final Color appBar;
  final Color progress;

  const ReaderTheme({
    required this.background,
    required this.text,
    required this.appBar,
    required this.progress,
  });

  static const Map<String, ReaderTheme> themes = {
    'paper': ReaderTheme(
      background: Color(0xFFF5F0E8),
      text: Color(0xFF3C3C3C),
      appBar: Colors.white,
      progress: Colors.orange,
    ),
    'white': ReaderTheme(
      background: Colors.white,
      text: Color(0xFF333333),
      appBar: Colors.white,
      progress: Colors.blue,
    ),
    'dark': ReaderTheme(
      background: Color(0xFF1E1E1E),
      text: Color(0xFFCCCCCC),
      appBar: Color(0xFF2D2D2D),
      progress: Colors.tealAccent,
    ),
    'green': ReaderTheme(
      background: Color(0xFFC7EDCC),
      text: Color(0xFF2C4C3B),
      appBar: Color(0xFFE8F5E9),
      progress: Colors.green,
    ),
  };
}

/// ═══════════════════════════════════════════════════
class ReaderSettingsPanel extends StatefulWidget {
  final ReaderSettings settings;
  final ValueChanged<ReaderSettings> onChanged;

  const ReaderSettingsPanel({required this.settings, required this.onChanged});

  @override
  State<ReaderSettingsPanel> createState() => ReaderSettingsPanelState();
}

class ReaderSettingsPanelState extends State<ReaderSettingsPanel> {
  late ReaderSettings _s;

  @override
  void initState() {
    super.initState();
    _s = widget.settings;
  }

  void _update(ReaderSettings s) {
    setState(() => _s = s);
    widget.onChanged(s);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _pickFont() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        Widget tile(String family, String label) {
          final selected = _s.fontFamily == family;
          return ListTile(
            title: Text(
              label,
              style: TextStyle(
                fontFamily: family.isEmpty ? null : family,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            trailing: selected
                ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                : null,
            onTap: () => Navigator.pop(ctx, family),
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '选择字体',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              tile('', '系统默认'),
              tile('serif', '衬线（serif）'),
              tile('monospace', '等宽（monospace）'),
              ListTile(
                leading: const Icon(Icons.upload_file_outlined),
                title: const Text('导入自定义字体'),
                subtitle: const Text('尚未实现 · 对齐 dialog_font_select'),
                onTap: () {
                  Navigator.pop(ctx);
                  _toast('自定义字体导入尚未实现');
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked != null) {
      _update(_s.copyWith(fontFamily: picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  const Text(
                    '阅读设置',
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
            const Divider(),

            // ── 字体 ──
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: const Icon(Icons.font_download_outlined, size: 22),
              title: const Text('字体', style: TextStyle(fontSize: 13)),
              subtitle: Text(_s.fontLabel, style: const TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: _pickFont,
            ),

            // ── 字体大小 ──
            _sliderBlock(
              label: '字体大小',
              leading: const Icon(Icons.text_fields, size: 20),
              value: _s.fontSize,
              min: 12,
              max: 32,
              divisions: 20,
              valueText: '${_s.fontSize.toInt()}',
              onChanged: (v) => _update(_s.copyWith(fontSize: v)),
            ),
            const SizedBox(height: 4),

            // ── 行距 ──
            _sliderBlock(
              label: '行距',
              leading: const Text('A', style: TextStyle(fontSize: 12)),
              value: _s.lineHeight,
              min: 1.2,
              max: 2.5,
              divisions: 13,
              valueText: _s.lineHeight.toStringAsFixed(1),
              onChanged: (v) => _update(_s.copyWith(lineHeight: v)),
            ),
            const SizedBox(height: 4),

            // ── 边距 ──
            _sliderBlock(
              label: '左右边距',
              leading: const Icon(Icons.swap_horiz, size: 18),
              value: _s.paddingHorizontal,
              min: 8,
              max: 48,
              divisions: 20,
              valueText: '${_s.paddingHorizontal.toInt()}',
              onChanged: (v) =>
                  _update(_s.copyWith(paddingHorizontal: v.roundToDouble())),
            ),
            _sliderBlock(
              label: '上下边距',
              leading: const Icon(Icons.swap_vert, size: 18),
              value: _s.paddingVertical,
              min: 0,
              max: 32,
              divisions: 16,
              valueText: '${_s.paddingVertical.toInt()}',
              onChanged: (v) =>
                  _update(_s.copyWith(paddingVertical: v.roundToDouble())),
            ),
            const SizedBox(height: 8),

            // ── 翻页模式 ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('翻页模式', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _ModeChip(
                        icon: Icons.swipe,
                        label: '左右翻页',
                        selected: _s.pageMode == 'slide',
                        onTap: () => _update(_s.copyWith(pageMode: 'slide')),
                      ),
                      const SizedBox(width: 12),
                      _ModeChip(
                        icon: Icons.unfold_more,
                        label: '下滑翻页',
                        selected: _s.pageMode == 'scroll',
                        onTap: () => _update(_s.copyWith(pageMode: 'scroll')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── 阅读主题 ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('阅读主题', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ThemeDot(
                        color: const Color(0xFFF5F0E8),
                        name: '米黄',
                        selected: _s.themeName == 'paper',
                        onTap: () => _update(_s.copyWith(themeName: 'paper')),
                      ),
                      _ThemeDot(
                        color: Colors.white,
                        name: '白',
                        selected: _s.themeName == 'white',
                        onTap: () => _update(_s.copyWith(themeName: 'white')),
                      ),
                      _ThemeDot(
                        color: const Color(0xFF1E1E1E),
                        name: '暗黑',
                        selected: _s.themeName == 'dark',
                        onTap: () => _update(_s.copyWith(themeName: 'dark')),
                      ),
                      _ThemeDot(
                        color: const Color(0xFFC7EDCC),
                        name: '护眼绿',
                        selected: _s.themeName == 'green',
                        onTap: () => _update(_s.copyWith(themeName: 'green')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),

            // ── 信息区开关 ──
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text('信息区', style: TextStyle(fontSize: 13)),
            ),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              dense: true,
              title: const Text('显示页码', style: TextStyle(fontSize: 13)),
              value: _s.showPageInfo,
              onChanged: (v) => _update(_s.copyWith(showPageInfo: v)),
            ),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              dense: true,
              title: const Text('显示时间', style: TextStyle(fontSize: 13)),
              value: _s.showTime,
              onChanged: (v) => _update(_s.copyWith(showTime: v)),
            ),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              dense: true,
              title: const Text('显示电量', style: TextStyle(fontSize: 13)),
              subtitle: const Text(
                '未接 battery 插件时显示占位',
                style: TextStyle(fontSize: 11),
              ),
              value: _s.showBattery,
              onChanged: (v) => _update(_s.copyWith(showBattery: v)),
            ),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              dense: true,
              title: const Text('音量键翻页', style: TextStyle(fontSize: 13)),
              subtitle: const Text(
                '部分桌面环境可能无效',
                style: TextStyle(fontSize: 11),
              ),
              value: _s.volumeKeyTurnPage,
              onChanged: (v) => _update(_s.copyWith(volumeKeyTurnPage: v)),
            ),

            const Divider(),

            // ── 明确占位入口（勿静默） ──
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              dense: true,
              leading: const Icon(Icons.record_voice_over_outlined, size: 22),
              title: const Text('朗读 (TTS)', style: TextStyle(fontSize: 13)),
              subtitle: const Text(
                '尚未实现 · dialog_read_aloud',
                style: TextStyle(fontSize: 11),
              ),
              onTap: () => _toast('TTS 朗读尚未实现'),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              dense: true,
              leading: const Icon(Icons.auto_stories_outlined, size: 22),
              title: const Text('自动阅读', style: TextStyle(fontSize: 13)),
              subtitle: const Text(
                '尚未实现 · dialog_auto_read',
                style: TextStyle(fontSize: 11),
              ),
              onTap: () => _toast('自动阅读尚未实现'),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              dense: true,
              leading: const Icon(Icons.touch_app_outlined, size: 22),
              title: const Text('点击区域', style: TextStyle(fontSize: 13)),
              subtitle: const Text(
                '尚未实现 · dialog_click_action_config',
                style: TextStyle(fontSize: 11),
              ),
              onTap: () => _toast('点击区域配置尚未实现'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sliderBlock({
    required String label,
    required Widget leading,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String valueText,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 4),
          Row(
            children: [
              leading,
              Expanded(
                child: Slider(
                  value: value.clamp(min, max),
                  min: min,
                  max: max,
                  divisions: divisions,
                  label: valueText,
                  onChanged: onChanged,
                ),
              ),
              Text(valueText, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

/// 翻页模式选择标签
class _ModeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 主题色圆点选择器
class _ThemeDot extends StatelessWidget {
  final Color color;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeDot({
    required this.color,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[300]!,
                width: selected ? 3 : 1,
              ),
              boxShadow: [
                if (selected)
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(name, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
