import '../../domain/book/book.dart';

/// 书籍详情页写入读完/N 刷轮次的 application 边界。
abstract interface class BookReadStatusPort {
  Future<void> updateReadIteration(Book book, int readIteration);
}

/// 独立宿主未提供阅读状态写入能力时的回调实现。
final class BookReadStatusPortCallbacks implements BookReadStatusPort {
  const BookReadStatusPortCallbacks({required UpdateReadIteration update})
    : _update = update;

  final UpdateReadIteration _update;

  @override
  Future<void> updateReadIteration(Book book, int readIteration) =>
      _update(book, readIteration);
}

typedef UpdateReadIteration =
    Future<void> Function(Book book, int readIteration);
