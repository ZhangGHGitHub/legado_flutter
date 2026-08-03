import '../../application/bookshelf/bookshelf_arrange_group_command_port.dart';
import '../../domain/book/book.dart';

/// 将现有 BookProvider 分组命令接入书架整理页 application 端口。
final class BookshelfArrangeGroupCommandPortAdapter
    implements BookshelfArrangeGroupCommandPort {
  const BookshelfArrangeGroupCommandPortAdapter({
    required Future<void> Function(String bookId, String group) updateBookGroup,
    required Future<void> Function(Iterable<String> bookIds, String group)
    updateBooksGroup,
    required List<Book> Function() books,
  }) : _updateBookGroup = updateBookGroup,
       _updateBooksGroup = updateBooksGroup,
       _books = books;

  final Future<void> Function(String bookId, String group) _updateBookGroup;
  final Future<void> Function(Iterable<String> bookIds, String group)
  _updateBooksGroup;
  final List<Book> Function() _books;

  @override
  Future<List<Book>> updateBookGroup(String bookId, String group) async {
    await _updateBookGroup(bookId, group);
    return List<Book>.unmodifiable(_books());
  }

  @override
  Future<List<Book>> updateBooksGroup(
    Iterable<String> bookIds,
    String group,
  ) async {
    final ids = List<String>.of(bookIds);
    await _updateBooksGroup(ids, group);
    return List<Book>.unmodifiable(_books());
  }
}
