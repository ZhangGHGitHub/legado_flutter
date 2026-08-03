import '../../domain/book/book.dart';

/// 书架整理页的分组写入命令边界。
abstract interface class BookshelfArrangeGroupCommandPort {
  Future<List<Book>> updateBookGroup(String bookId, String group);

  Future<List<Book>> updateBooksGroup(Iterable<String> bookIds, String group);

  /// 逐本清空分组；null 表示无条件，非 null 表示精确匹配后清空。
  Future<List<Book>> clearBooksGroup(
    Iterable<String> bookIds, {
    String? onlyWhenGroupEquals,
  });
}
