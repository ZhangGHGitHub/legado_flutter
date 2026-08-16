import '../../application/bookshelf/remote_book_import_port.dart';
import '../../domain/book/book.dart';

/// 将现有 BookProvider 的本地书架导入能力接入远程书籍页端口。
final class RemoteBookImportPortAdapter implements RemoteBookImportPort {
  const RemoteBookImportPortAdapter({
    required List<Book> Function() books,
    required Future<Book?> Function(String path, {required String displayName})
    importLocalBookFromPath,
  }) : _books = books,
       _importLocalBookFromPath = importLocalBookFromPath;

  final List<Book> Function() _books;
  final Future<Book?> Function(String path, {required String displayName})
  _importLocalBookFromPath;

  @override
  List<Book> get books => List<Book>.unmodifiable(_books());

  @override
  Future<Book?> importLocalBookFromPath(
    String path, {
    required String displayName,
  }) => _importLocalBookFromPath(path, displayName: displayName);
}
