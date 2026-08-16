import 'package:flutter/material.dart';

import 'package:legado_flutter/domain/book/book.dart';
import '../../application/bookshelf/bookshelf_display_port.dart';
import '../../theme/legado_tokens.dart';
import '../../widgets/book_cover.dart';
import '../../widgets/legado_refresh_indicator.dart';
import '../../widgets/shelf_unread_badge.dart';

/// 书架书籍区 — 按 [BookshelfConfig.bookshelfLayout] 渲染列表或网格。
class BookshelfBooksView extends StatelessWidget {
  const BookshelfBooksView({
    super.key,
    required this.config,
    required this.books,
    required this.pinnedIds,
    required this.isUpdating,
    required this.onTap,
    required this.onLongPress,
    this.scrollController,
  });

  final BookshelfConfig config;
  final List<Book> books;
  final Set<String> pinnedIds;
  final bool Function(String bookId) isUpdating;
  final void Function(Book book) onTap;
  final void Function(Book book) onLongPress;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final margin = config.bookshelfMargin.toDouble();
    final child = config.isGrid
        ? _buildGrid(context, margin)
        : _buildList(context, margin);

    if (!config.showBookshelfFastScroller) return child;

    return Scrollbar(
      controller: scrollController,
      thumbVisibility: true,
      child: child,
    );
  }

  Widget _buildList(BuildContext context, double margin) {
    final compact = config.isCompactList;
    return ListView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        vertical: compact ? 4 : LegadoTokens.spacingSm,
        horizontal: margin,
      ),
      itemCount: books.length,
      itemBuilder: (_, i) {
        final book = books[i];
        return BookshelfListTile(
          book: book,
          config: config,
          isPinned: pinnedIds.contains(book.id),
          isUpdating: isUpdating(book.id),
          compact: compact,
          onTap: () => onTap(book),
          onLongPress: () => onLongPress(book),
        );
      },
    );
  }

  Widget _buildGrid(BuildContext context, double margin) {
    final cols = config.gridColumns;
    final showName = config.showBookname != 1;
    final overlay = config.showBookname == 2;
    return GridView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(margin > 0 ? margin : LegadoDimens.pageVertical),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: showName && !overlay ? 0.52 : 0.68,
      ),
      itemCount: books.length,
      itemBuilder: (_, i) {
        final book = books[i];
        return BookshelfGridTile(
          book: book,
          config: config,
          isUpdating: isUpdating(book.id),
          onTap: () => onTap(book),
          onLongPress: () => onLongPress(book),
        );
      },
    );
  }
}

class BookshelfListTile extends StatelessWidget {
  const BookshelfListTile({
    super.key,
    required this.book,
    required this.config,
    required this.isPinned,
    required this.isUpdating,
    required this.onTap,
    required this.onLongPress,
    this.compact = false,
  });

  final Book book;
  final BookshelfConfig config;
  final bool isPinned;
  final bool isUpdating;
  final bool compact;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;
    final coverH = compact ? 64.0 : LegadoTokens.coverListHeight;
    final coverW = compact ? 48.0 : LegadoTokens.coverListWidth;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: LegadoTokens.spacingMd,
          vertical: compact ? 6 : LegadoTokens.spacingSm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookCover(
              coverUrl: book.coverUrl,
              author: book.author,
              width: coverW,
              height: coverH,
              radius: LegadoTokens.radiusSmall,
            ),
            const SizedBox(width: LegadoTokens.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isPinned) ...[
                        Icon(Icons.push_pin, size: 14, color: scheme.primary),
                        const SizedBox(width: LegadoTokens.spacingXs),
                      ],
                      Expanded(
                        child: Text(
                          book.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? 15 : 16,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 6),
                    _meta(
                      Icons.person_outline,
                      book.author.isNotEmpty ? book.author : '未知作者',
                      muted,
                    ),
                    const SizedBox(height: LegadoTokens.spacingXs),
                    _meta(
                      Icons.access_time,
                      book.currentChapter?.isNotEmpty == true
                          ? book.currentChapter!
                          : '尚未开始阅读',
                      muted,
                    ),
                    const SizedBox(height: LegadoTokens.spacingXs),
                    _meta(
                      Icons.explore_outlined,
                      book.lastChapter?.isNotEmpty == true
                          ? book.lastChapter!
                          : '暂无更新',
                      muted.withValues(alpha: 0.85),
                    ),
                    if (config.showLastUpdateTime &&
                        (book.updatedAt?.isNotEmpty ?? false)) ...[
                      const SizedBox(height: LegadoTokens.spacingXs),
                      _meta(
                        Icons.update,
                        '更新 ${book.updatedAt}',
                        muted.withValues(alpha: 0.75),
                      ),
                    ],
                  ] else ...[
                    const SizedBox(height: 4),
                    Text(
                      book.author.isNotEmpty ? book.author : '未知作者',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: LegadoTokens.spacingSm),
            if (isUpdating)
              const LegadoShelfUpdatingIndicator()
            else if (config.showUnread)
              ShelfUnreadBadge(book: book),
          ],
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: LegadoTokens.spacingXs),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: color),
          ),
        ),
      ],
    );
  }
}

class BookshelfGridTile extends StatelessWidget {
  const BookshelfGridTile({
    super.key,
    required this.book,
    required this.config,
    required this.isUpdating,
    required this.onTap,
    required this.onLongPress,
  });

  final Book book;
  final BookshelfConfig config;
  final bool isUpdating;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final showName = config.showBookname != 1;
    final overlay = config.showBookname == 2;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: LegadoTokens.coverRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                BookCover(
                  coverUrl: book.coverUrl,
                  author: book.author,
                  width: double.infinity,
                  radius: LegadoTokens.radiusCover,
                ),
                if (overlay && showName)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      color: Colors.black54,
                      child: Text(
                        book.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: LegadoTokens.spacingXs,
                  right: LegadoTokens.spacingXs,
                  child: isUpdating
                      ? const LegadoShelfUpdatingIndicator(size: 22)
                      : (config.showUnread
                            ? ShelfUnreadBadge(book: book)
                            : const SizedBox.shrink()),
                ),
              ],
            ),
          ),
          if (showName && !overlay) ...[
            const SizedBox(height: 6),
            Text(
              book.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            if (book.author.isNotEmpty)
              Text(
                book.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ],
      ),
    );
  }
}
