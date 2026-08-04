import '../../application/bookshelf/bookshelf_arrange_snapshot_port.dart';
import '../../domain/book/book.dart';

/// 将现有书架事实源的同步快照接入整理页 application 端口。
final class BookshelfArrangeSnapshotPortAdapter
    implements BookshelfArrangeSnapshotPort {
  const BookshelfArrangeSnapshotPortAdapter(this._books);

  final List<Book> Function() _books;

  @override
  List<Book> get books => List<Book>.unmodifiable(_books());
}
