import '../../application/reader/reader_image_headers_port.dart';
import '../../domain/book/book.dart';

typedef ReaderImageHeadersLoader =
    Future<Map<String, String>> Function(Book book);

/// 以回调形式复用现有 SourceProvider 的图片请求头读取行为。
final class ReaderImageHeadersPortAdapter implements ReaderImageHeadersPort {
  const ReaderImageHeadersPortAdapter({
    required ReaderImageHeadersLoader imageHeadersForBook,
  }) : _imageHeadersForBook = imageHeadersForBook;

  final ReaderImageHeadersLoader _imageHeadersForBook;

  @override
  Future<Map<String, String>> imageHeadersForBook(Book book) =>
      _imageHeadersForBook(book);
}
