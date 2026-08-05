import '../../application/bookshelf/bookshelf_book_lifecycle_port.dart';
import '../../domain/book/book.dart';

/// 将现有 BookProvider 的书架生命周期操作接入 application 端口。
final class BookshelfBookLifecyclePortAdapter
    implements BookshelfBookLifecyclePort {
  const BookshelfBookLifecyclePortAdapter({
    required Future<void> Function(Book book) addBook,
    required Future<void> Function(Book book) persistCurrentTocFor,
    required Future<void> Function(String bookId) removeBook,
  }) : _addBook = addBook,
       _persistCurrentTocFor = persistCurrentTocFor,
       _removeBook = removeBook;

  final Future<void> Function(Book book) _addBook;
  final Future<void> Function(Book book) _persistCurrentTocFor;
  final Future<void> Function(String bookId) _removeBook;

  @override
  Future<void> addBook(Book book) => _addBook(book);

  @override
  Future<void> persistCurrentTocFor(Book book) => _persistCurrentTocFor(book);

  @override
  Future<void> removeBook(String bookId) => _removeBook(bookId);
}
