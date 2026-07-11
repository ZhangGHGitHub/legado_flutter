import 'package:flutter/material.dart';

/// 阅读进度角标（书架 style1）
class ReadBadge extends StatelessWidget {
  final double progress;
  final String? currentChapter;

  const ReadBadge({super.key, required this.progress, this.currentChapter});

  @override
  Widget build(BuildContext context) {
    if (progress <= 0 && (currentChapter == null || currentChapter!.isEmpty)) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final label = progress > 0
        ? '${(progress * 100).toInt()}%'
        : (currentChapter != null && currentChapter!.isNotEmpty ? '在读' : '');

    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: theme.colorScheme.tertiary),
      ),
    );
  }
}
