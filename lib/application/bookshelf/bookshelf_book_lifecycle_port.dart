import '../../domain/book/book.dart';

/// 书籍详情页加入、移除书架及当前目录保存的 application 边界。
abstract interface class BookshelfBookLifecyclePort {
  Future<void> addBook(Book book);

  Future<void> persistCurrentTocFor(Book book);

  Future<void> removeBook(String bookId);
}

/// 独立宿主未提供书架书籍生命周期能力时的明确空实现。
final class EmptyBookshelfBookLifecyclePort
    implements BookshelfBookLifecyclePort {
  const EmptyBookshelfBookLifecyclePort();

  static UnsupportedError _unavailable() => UnsupportedError('书架书籍服务不可用');

  @override
  Future<void> addBook(Book book) => Future<void>.error(_unavailable());

  @override
  Future<void> persistCurrentTocFor(Book book) =>
      Future<void>.error(_unavailable());

  @override
  Future<void> removeBook(String bookId) => Future<void>.error(_unavailable());
}
