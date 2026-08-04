import '../../domain/book/book.dart';

/// 阅读器获取书籍图片请求头的应用层边界。
abstract interface class ReaderImageHeadersPort {
  Future<Map<String, String>> imageHeadersForBook(Book book);
}
