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
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        // width: infinity（网格 Expanded）时勿用 width*1.33，否则 h=Infinity 触发布局断言
        final w = width.isFinite
            ? width
            : (constraints.maxWidth.isFinite && constraints.maxWidth > 0
                  ? constraints.maxWidth
                  : LegadoTokens.bookCoverWidthList);
        final h = (height != null && height!.isFinite)
            ? height!
            : (constraints.maxHeight.isFinite &&
                      constraints.maxHeight > 0 &&
                      constraints.maxHeight < double.infinity
                  ? constraints.maxHeight
                  : w * 1.33);
        final iconSize = (w.isFinite ? w : LegadoTokens.bookCoverWidthList) * 0.35;

        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: SizedBox(
            width: w.isFinite ? w : null,
            height: h.isFinite ? h : null,
            child: coverUrl.isNotEmpty
                ? Image.network(
                    coverUrl,
                    fit: BoxFit.cover,
                    width: w.isFinite ? w : null,
                    height: h.isFinite ? h : null,
                    errorBuilder: (_, _, _) =>
                        _placeholder(theme, iconSize),
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return _placeholder(theme, iconSize);
                    },
                  )
                : _placeholder(theme, iconSize),
          ),
        );
      },
    );
  }

  Widget _placeholder(ThemeData theme, double iconSize) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book,
            size: iconSize.isFinite ? iconSize : 24,
            color: theme.colorScheme.primary,
          ),
          if (author != null && author!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                author!.length > 4 ? author!.substring(0, 4) : author!,
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
