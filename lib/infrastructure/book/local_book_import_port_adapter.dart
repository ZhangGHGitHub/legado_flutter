import '../../application/book/local_book_import_port.dart';
import '../../domain/book/book.dart';
import '../../services/local_book_service.dart' as legacy;

/// 将现有本地书籍导入服务接入 application 端口。
final class LocalBookImportPortAdapter implements LocalBookImportPort {
  const LocalBookImportPortAdapter(this._service);

  final legacy.LocalBookService _service;

  @override
  Future<Book?> importFromFile() async {
    try {
      return await _service.importFromFile();
    } on legacy.LocalBookImportException catch (error) {
      throw LocalBookImportPortException(error.message);
    }
  }

  @override
  Future<Book> importFromPath(String filePath, {String? displayName}) async {
    try {
      return await _service.importFromPath(filePath, displayName: displayName);
    } on legacy.LocalBookImportException catch (error) {
      throw LocalBookImportPortException(error.message);
    }
  }
}
