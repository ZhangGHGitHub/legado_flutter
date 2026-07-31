import '../../domain/book/book_group.dart';

/// 书架整理页所需的分组目录端口。
abstract interface class BookGroupStorePort {
  List<BookGroup> get cached;

  Future<void> syncNamesFromBooks(Iterable<String> names);
}
