import '../../application/bookshelf/bookshelf_arrange_delete_command_port.dart';

/// 将现有 BookProvider 删除命令接入书架整理页 application 端口。
final class BookshelfArrangeDeleteCommandPortAdapter
    implements BookshelfArrangeDeleteCommandPort {
  const BookshelfArrangeDeleteCommandPortAdapter({
    required Future<void> Function(String bookId) removeBook,
    required Future<void> Function(Iterable<String> bookIds) removeBooks,
  }) : _removeBook = removeBook,
       _removeBooks = removeBooks;

  final Future<void> Function(String bookId) _removeBook;
  final Future<void> Function(Iterable<String> bookIds) _removeBooks;

  @override
  Future<void> removeBook(String bookId) => _removeBook(bookId);

  @override
  Future<void> removeBooks(Iterable<String> bookIds) =>
      _removeBooks(List<String>.of(bookIds));
}
