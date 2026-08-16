import '../../application/bookshelf/bookshelf_toc_refresh_port.dart';
import '../../domain/book/book.dart';

/// 将现有 BookProvider 的目录刷新能力接入 application 端口。
final class BookshelfTocRefreshPortAdapter implements BookshelfTocRefreshPort {
  const BookshelfTocRefreshPortAdapter({
    required BookshelfTocRefresh refresh,
    required bool Function() isRunning,
  }) : _refresh = refresh,
       _isRunning = isRunning;

  final BookshelfTocRefresh _refresh;
  final bool Function() _isRunning;

  @override
  bool get isRunning => _isRunning();

  @override
  Future<ShelfTocUpdateResult> refresh(
    Iterable<Book> books, {
    required BookshelfTocSourceResolver resolveSource,
    bool onlyUpdateRead = false,
    int concurrency = 3,
  }) => _refresh(
    books,
    resolveSource: resolveSource,
    onlyUpdateRead: onlyUpdateRead,
    concurrency: concurrency,
  );
}
