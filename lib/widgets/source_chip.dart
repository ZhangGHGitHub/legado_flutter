import 'package:flutter/material.dart';

import '../theme/legado_tokens.dart';

/// 书源选择 Chip（发现 Tab 横向列表）
class SourceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool hasExplore;
  final VoidCallback onTap;

  const SourceChip({
    super.key,
    required this.label,
    required this.selected,
    this.hasExplore = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: LegadoTokens.spacingSm),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasExplore)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 4),
                decoration: const BoxDecoration(
                  color: LegadoTokens.sourceDotGreen,
                  shape: BoxShape.circle,
                ),
              ),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: selected ? theme.colorScheme.onPrimaryContainer : null,
                ),
              ),
            ),
          ],
        ),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}
