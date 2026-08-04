import '../../application/bookshelf/bookshelf_url_import_port.dart';
import '../../domain/source/book_source.dart';

/// 将现有 BookProvider URL 入库方法接入 application 端口。
final class BookshelfUrlImportPortAdapter implements BookshelfUrlImportPort {
  const BookshelfUrlImportPortAdapter(this._addBooksByUrls);

  final Future<({int success, int fail})> Function(
    String rawText, {
    required List<BookSource> sources,
    BookshelfUrlImportProgress? onProgress,
  })
  _addBooksByUrls;

  @override
  Future<({int success, int fail})> addBooksByUrls(
    String rawText, {
    required List<BookSource> sources,
    BookshelfUrlImportProgress? onProgress,
  }) => _addBooksByUrls(rawText, sources: sources, onProgress: onProgress);
}
