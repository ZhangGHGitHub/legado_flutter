import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════
class ReaderSettings {
  final double fontSize;
  final double lineHeight;
  final String themeName; // 'paper' | 'white' | 'dark' | 'green'
  final String pageMode; // 'slide' | 'scroll'

  const ReaderSettings({
    this.fontSize = 18.0,
    this.lineHeight = 1.8,
    this.themeName = 'paper',
    this.pageMode = 'slide',
  });

  ReaderSettings copyWith({
    double? fontSize,
    double? lineHeight,
    String? themeName,
    String? pageMode,
  }) {
    return ReaderSettings(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      themeName: themeName ?? this.themeName,
      pageMode: pageMode ?? this.pageMode,
    );
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题 + 关闭按钮
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

          // ── 字体大小 ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('字体大小', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.text_fields, size: 20),
                    Expanded(
                      child: Slider(
                        value: _s.fontSize,
                        min: 12,
                        max: 32,
                        divisions: 20,
                        label: '${_s.fontSize.toInt()}',
                        onChanged: (v) => _update(_s.copyWith(fontSize: v)),
                      ),
                    ),
                    Text(
                      '${_s.fontSize.toInt()}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── 行距 ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('行距', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('A', style: TextStyle(fontSize: 12)),
                    Expanded(
                      child: Slider(
                        value: _s.lineHeight,
                        min: 1.2,
                        max: 2.5,
                        divisions: 13,
                        label: _s.lineHeight.toStringAsFixed(1),
                        onChanged: (v) => _update(_s.copyWith(lineHeight: v)),
                      ),
                    ),
                    Text(
                      _s.lineHeight.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
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
          const SizedBox(height: 16),
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