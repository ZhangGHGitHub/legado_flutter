import 'package:flutter/material.dart';

import '../theme/legado_tokens.dart';

/// 我的页快捷四格按钮（对齐 MyFragment initQuickActions）
class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalColor = theme.colorScheme.surfaceContainerHighest;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: LegadoTokens.cardRadius,
        child: Ink(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: normalColor,
            borderRadius: LegadoTokens.cardRadius,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: theme.colorScheme.primary),
              const SizedBox(height: LegadoTokens.spacingXs),
              Text(
                label,
                style: const TextStyle(fontSize: 10),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
