import '../../domain/book/book.dart';

/// 书架整理页的分组写入命令边界。
abstract interface class BookshelfArrangeGroupCommandPort {
  Future<List<Book>> updateBookGroup(String bookId, String group);

  Future<List<Book>> updateBooksGroup(Iterable<String> bookIds, String group);
}
