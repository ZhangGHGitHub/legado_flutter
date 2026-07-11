import 'package:flutter/material.dart';

import '../theme/legado_tokens.dart';

/// 书籍封面（列表 / 网格 / 详情共用）
class BookCover extends StatelessWidget {
  final String coverUrl;
  final String? author;
  final double width;
  final double? height;
  final double radius;

  const BookCover({
    super.key,
    required this.coverUrl,
    this.author,
    this.width = LegadoTokens.bookCoverWidthList,
    this.height,
    this.radius = LegadoTokens.radiusCover,
  });

  @override
  Widget build(BuildContext context) {
    final h = height ?? width * 1.33;
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: h,
        child: coverUrl.isNotEmpty
            ? Image.network(
                coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(theme),
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return _placeholder(theme);
                },
              )
            : _placeholder(theme),
      ),
    );
  }

  Widget _placeholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: width * 0.35, color: theme.colorScheme.primary),
          if (author != null && author!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                author!.length > 4 ? author!.substring(0, 4) : author!,
                style: TextStyle(fontSize: 10, color: theme.colorScheme.primary),
              ),
            ),
        ],
      ),
    );
  }
}
