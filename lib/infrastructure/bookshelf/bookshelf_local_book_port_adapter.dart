import '../../application/bookshelf/bookshelf_local_book_port.dart';
import '../../domain/book/book.dart';
import '../../services/local_book_service.dart';

/// 将现有 BookProvider 的本地导入回调接入书架应用端口。
///
/// BookProvider 仍负责导入后的书架状态刷新；adapter 只隔离 legacy service
/// 的异常类型，避免该类型泄漏到页面层。
final class BookshelfLocalBookPortAdapter implements BookshelfLocalBookPort {
  const BookshelfLocalBookPortAdapter(this._import);

  final Future<Book?> Function() _import;

  @override
  Future<Book?> importLocalBook() async {
    try {
      return await _import();
    } on LocalBookImportException catch (error) {
      throw BookshelfLocalBookImportException(error.message);
    }
  }
}
