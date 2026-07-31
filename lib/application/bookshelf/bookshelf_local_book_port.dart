import '../../domain/book/book.dart';

/// 书架本地书导入所需的应用端口。
///
/// 页面不直接依赖本地文件服务；导入完成后由现有 BookProvider 负责刷新书架状态。
abstract interface class BookshelfLocalBookPort {
  Future<Book?> importLocalBook();
}

/// 可直接展示给用户的本地书导入错误。
final class BookshelfLocalBookImportException implements Exception {
  const BookshelfLocalBookImportException(this.message);

  final String message;

  @override
  String toString() => message;
}
