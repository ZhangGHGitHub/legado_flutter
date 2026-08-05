import '../../application/book/book_metadata_port.dart';
import '../../domain/book/book.dart';

/// 将现有 BookProvider 的元数据写入和书架快照同步接入 application 端口。
final class BookMetadataPortAdapter implements BookMetadataPort {
  const BookMetadataPortAdapter({
    required Future<Book> Function(Book book, String coverUrl) updateCover,
    required Future<Book?> Function(
      String bookId, {
      required String name,
      required String author,
      required String description,
    })
    updateBookDetails,
  }) : _updateCover = updateCover,
       _updateBookDetails = updateBookDetails;

  final Future<Book> Function(Book book, String coverUrl) _updateCover;
  final Future<Book?> Function(
    String bookId, {
    required String name,
    required String author,
    required String description,
  })
  _updateBookDetails;

  @override
  Future<Book> updateCover(Book book, String coverUrl) =>
      _updateCover(book, coverUrl);

  @override
  Future<Book?> updateBookDetails(
    String bookId, {
    required String name,
    required String author,
    required String description,
  }) => _updateBookDetails(
    bookId,
    name: name,
    author: author,
    description: description,
  );
}
