import '../../domain/book/book.dart';
import '../../domain/source/book_source.dart';

/// 书架目录刷新结果，供 UI 展示完整的成功、失败和跳过统计。
class ShelfTocUpdateResult {
  const ShelfTocUpdateResult({
    required this.requested,
    required this.eligible,
    required this.updated,
    required this.failed,
    required this.skipped,
    this.failures = const <String, String>{},
  });

  final int requested;
  final int eligible;
  final int updated;
  final int failed;
  final int skipped;
  final Map<String, String> failures;
}

typedef BookshelfTocSourceResolver = BookSource? Function(Book book);

typedef BookshelfTocRefresh =
    Future<ShelfTocUpdateResult> Function(
      Iterable<Book> books, {
      required BookshelfTocSourceResolver resolveSource,
      bool onlyUpdateRead,
      int concurrency,
    });

/// 书架目录刷新所需的 application 命令边界。
abstract interface class BookshelfTocRefreshPort {
  bool get isRunning;

  Future<ShelfTocUpdateResult> refresh(
    Iterable<Book> books, {
    required BookshelfTocSourceResolver resolveSource,
    bool onlyUpdateRead = false,
    int concurrency = 3,
  });
}

/// 独立页面宿主未提供目录刷新能力时的空实现。
final class EmptyBookshelfTocRefreshPort implements BookshelfTocRefreshPort {
  const EmptyBookshelfTocRefreshPort();

  @override
  bool get isRunning => false;

  @override
  Future<ShelfTocUpdateResult> refresh(
    Iterable<Book> books, {
    required BookshelfTocSourceResolver resolveSource,
    bool onlyUpdateRead = false,
    int concurrency = 3,
  }) async {
    final requested = books.length;
    return ShelfTocUpdateResult(
      requested: requested,
      eligible: 0,
      updated: 0,
      failed: 0,
      skipped: requested,
    );
  }
}
