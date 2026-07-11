import 'package:flutter/material.dart';

/// 我的 / 设置列表行（对齐 MyFragment item 样式）
class LegadoListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const LegadoListTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }
}

class LegadoListDivider extends StatelessWidget {
  const LegadoListDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 56);
  }
}
