import '../../domain/source/book_source.dart';

typedef BookshelfUrlImportProgress =
    void Function(int index, int total, String url);

/// 添加网址对话框所需的书架 URL 入库能力。
abstract interface class BookshelfUrlImportPort {
  Future<({int success, int fail})> addBooksByUrls(
    String rawText, {
    required List<BookSource> sources,
    BookshelfUrlImportProgress? onProgress,
  });
}
