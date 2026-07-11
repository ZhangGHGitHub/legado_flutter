import 'package:flutter/material.dart';

import '../reader/reader_settings.dart';

/// 主题设置 — 对齐 ThemeConfigFragment（F4 骨架）
class ThemeConfigPage extends StatelessWidget {
  const ThemeConfigPage({super.key});

  static const _presets = [
    ('paper', '米黄', Color(0xFFF5F0E8)),
    ('white', '纯白', Colors.white),
    ('dark', '暗黑', Color(0xFF1E1E1E)),
    ('green', '护眼绿', Color(0xFFC7EDCC)),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '阅读主题预设',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        ..._presets.map((p) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: p.$3,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor),
                ),
              ),
              title: Text(p.$2),
              subtitle: Text(
                '背景 #${p.$3.toARGB32().toRadixString(16).substring(2)}',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('「${p.$2}」主题编辑即将推出')),
                );
              },
            ),
          );
        }),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('主题导出功能开发中（对齐 Jingshiro README）')),
            );
          },
          icon: const Icon(Icons.upload_file),
          label: const Text('导出当前主题'),
        ),
        const SizedBox(height: 12),
        Text(
          '应用主题请在「我的 → 主题模式」切换',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
