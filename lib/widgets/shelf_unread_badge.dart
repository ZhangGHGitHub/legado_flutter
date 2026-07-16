import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../help/shelf_unread.dart';
import '../models/book.dart';
import '../providers/book_provider.dart';
import '../theme/legado_tokens.dart';

/// 书架未读/更新角标 — 结构对齐 legado BadgeView
class ShelfUnreadBadge extends StatelessWidget {
  final Book book;
  const ShelfUnreadBadge({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final meta = context.watch<BookProvider>().shelfChapterMeta(book.id);
    final result = ShelfUnread.evaluate(
      book: book,
      totalChapters: meta?.count,
      durChapterIndex: meta?.durIndex,
    );
    if (!result.visible) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final bg = result.highlight
        ? scheme.primary
        : scheme.onSurface.withValues(alpha: 0.28);
    final fg = result.highlight ? scheme.onPrimary : scheme.onSurface;

    final count = result.count;
    final label = count != null && count > 0
        ? (count > 999 ? '999+' : '$count')
        : '更新';

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(LegadoTokens.radiusSmall),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }
}
