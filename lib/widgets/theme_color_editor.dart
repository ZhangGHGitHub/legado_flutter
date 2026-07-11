import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../theme/theme_config_model.dart';

/// 12 色板编辑器
class ThemeColorEditor extends StatelessWidget {
  const ThemeColorEditor({super.key});

  static const _pickerSwatches = [
    Color(0xFF2196F3),
    Color(0xFF4CAF50),
    Color(0xFF8D6E63),
    Color(0xFF5C6BC0),
    Color(0xFFE53935),
    Color(0xFFFFB74D),
    Color(0xFF26A69A),
    Color(0xFF7E57C2),
    Color(0xFFF5F0E8),
    Color(0xFF1E1E1E),
    Color(0xFFFFFFFF),
    Color(0xFF121212),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ctrl = context.watch<ThemeModeController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '自定义色板（12 色）',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (ctrl.customColors.isNotEmpty)
              TextButton(
                onPressed: () => ctrl.clearCustomColors(),
                child: const Text('重置'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ...ThemeColorRoles.all.map((role) {
          final color = ctrl.customColors[role.id];
          return Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              dense: true,
              leading: GestureDetector(
                onTap: () => _pickColor(context, ctrl, role.id, color),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color ?? theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: color == null
                      ? Icon(Icons.palette_outlined, size: 18, color: theme.hintColor)
                      : null,
                ),
              ),
              title: Text(role.label, style: const TextStyle(fontSize: 14)),
              subtitle: Text(
                color != null
                    ? ThemeColorRoles.toHex(color)
                    : '跟随预设',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: color != null
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => ctrl.setCustomColor(role.id, null),
                    )
                  : null,
              onTap: () => _pickColor(context, ctrl, role.id, color),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _pickColor(
    BuildContext context,
    ThemeModeController ctrl,
    String roleId,
    Color? current,
  ) async {
    final picked = await showDialog<Color>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ThemeColorRoles.all.firstWhere((r) => r.id == roleId).label),
        content: SizedBox(
          width: 280,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _pickerSwatches.map((c) {
              final selected = current?.toARGB32() == c.toARGB32();
              return InkWell(
                onTap: () => Navigator.pop(ctx, c),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? Theme.of(ctx).colorScheme.primary : Colors.grey,
                      width: selected ? 2 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
        ],
      ),
    );
    if (picked != null) {
      await ctrl.setCustomColor(roleId, picked);
    }
  }
}
