import 'package:flutter/material.dart';

import '../models/book.dart';
import 'book_cover.dart';

/// 书籍列表行（搜索 / 发现结果共用）
class BookListTile extends StatelessWidget {
  final Book book;
  final String? sourceName;
  final VoidCallback onTap;

  const BookListTile({
    super.key,
    required this.book,
    this.sourceName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cleanSource = _cleanSourceName(sourceName);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: BookCover(coverUrl: book.coverUrl, author: book.author),
      title: Text(
        book.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      subtitle: Row(
        children: [
          if (book.author.isNotEmpty) ...[
            Flexible(
              child: Text(
                book.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
            if (cleanSource != null) const SizedBox(width: 8),
          ],
          if (cleanSource != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                cleanSource,
                style: TextStyle(fontSize: 10, color: theme.colorScheme.primary),
              ),
            ),
        ],
      ),
      trailing: Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  String? _cleanSourceName(String? name) {
    if (name == null || name.isEmpty) return null;
    final emojiRegex = RegExp(
      r'^[\u{1F000}-\u{1FFFF}\u{2000}-\u{2FFF}]\s*',
      unicode: true,
    );
    return name.replaceAll(emojiRegex, '').trim();
  }
}
