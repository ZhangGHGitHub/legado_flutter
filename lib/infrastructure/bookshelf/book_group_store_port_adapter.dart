import '../../application/bookshelf/book_group_store_port.dart';
import '../../domain/book/book_group.dart';
import '../../services/book_group_store.dart';

/// 将现有静态 BookGroupStore 暴露为书架整理页的应用端口。
final class BookGroupStorePortAdapter implements BookGroupStorePort {
  const BookGroupStorePortAdapter();

  @override
  List<BookGroup> get cached => BookGroupStore.cached;

  @override
  Future<void> syncNamesFromBooks(Iterable<String> names) =>
      BookGroupStore.syncNamesFromBooks(names);
}
