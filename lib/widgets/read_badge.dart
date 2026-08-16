import 'package:flutter/material.dart';

import '../application/book/book_read_status_policy.dart';
import '../domain/book/book.dart';

/// 阅读状态角标 — 「读完」/「N刷」优先，否则显示进度百分比
class ReadBadge extends StatelessWidget {
  final double progress;
  final String? currentChapter;
  final int readIteration;
  final VoidCallback? onTap;

  const ReadBadge({
    super.key,
    required this.progress,
    this.currentChapter,
    this.readIteration = 0,
    this.onTap,
  });

  factory ReadBadge.fromBook(Book book, {Key? key, VoidCallback? onTap}) {
    return ReadBadge(
      key: key,
      progress: book.progress,
      currentChapter: book.currentChapter,
      readIteration: book.readIteration,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = BookReadStatusPolicy.labelForReadIteration(readIteration);

    String label;
    Color bg;
    Color fg;
    if (status != null) {
      label = status;
      final finished = readIteration.isOdd;
      bg = finished
          ? Colors.green.withValues(alpha: 0.15)
          : theme.colorScheme.tertiaryContainer;
      fg = finished ? Colors.green.shade700 : theme.colorScheme.tertiary;
    } else if (progress > 0) {
      label = '${(progress * 100).toInt()}%';
      bg = theme.colorScheme.tertiaryContainer;
      fg = theme.colorScheme.tertiary;
    } else if (currentChapter != null && currentChapter!.isNotEmpty) {
      label = '在读';
      bg = theme.colorScheme.tertiaryContainer;
      fg = theme.colorScheme.tertiary;
    } else {
      return const SizedBox.shrink();
    }

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: fg)),
    );

    if (onTap == null) return chip;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: chip,
    );
  }
}
