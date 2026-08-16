import '../../application/book/book_read_status_port.dart';
import '../../domain/book/book.dart';

/// 将现有 BookProvider 的阅读状态写入接入 application 端口。
final class BookReadStatusPortAdapter implements BookReadStatusPort {
  const BookReadStatusPortAdapter({required UpdateReadIteration update})
    : _update = update;

  final UpdateReadIteration _update;

  @override
  Future<void> updateReadIteration(Book book, int readIteration) =>
      _update(book, readIteration);
}
