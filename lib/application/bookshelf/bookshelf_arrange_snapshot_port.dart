import '../../domain/book/book.dart';

/// 书架整理页读取当前完整书架快照所需的应用边界。
///
/// 该端口保持同步读取，避免整理页初始化、筛选和导出时引入新的异步
/// 时序；快照的生产和更新仍由书架事实源负责。
abstract interface class BookshelfArrangeSnapshotPort {
  List<Book> get books;
}

/// 独立测试宿主未提供书架快照时的空实现。
final class EmptyBookshelfArrangeSnapshotPort
    implements BookshelfArrangeSnapshotPort {
  const EmptyBookshelfArrangeSnapshotPort();

  @override
  List<Book> get books => const [];
}
