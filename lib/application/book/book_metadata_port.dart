import '../../domain/book/book.dart';

/// 书籍详情页封面和基础信息写入的 application 边界。
abstract interface class BookMetadataPort {
  Future<Book> updateCover(Book book, String coverUrl);

  Future<Book?> updateBookDetails(
    String bookId, {
    required String name,
    required String author,
    required String description,
  });
}

/// 详情页独立宿主未提供书籍元数据写入能力时的回调实现。
final class BookMetadataPortCallbacks implements BookMetadataPort {
  const BookMetadataPortCallbacks({
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

/// 独立宿主未提供书籍元数据写入能力时的明确空实现。
final class EmptyBookMetadataPort implements BookMetadataPort {
  const EmptyBookMetadataPort();

  @override
  Future<Book> updateCover(Book book, String coverUrl) =>
      Future<Book>.error(UnsupportedError('书籍元数据服务不可用'));

  @override
  Future<Book?> updateBookDetails(
    String bookId, {
    required String name,
    required String author,
    required String description,
  }) => Future<Book?>.error(UnsupportedError('书籍元数据服务不可用'));
}
