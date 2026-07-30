import '../../application/cache/book_cache_export_port.dart';
import '../../domain/book/book.dart';
import '../../domain/book/chapter.dart';
import '../../domain/ports/chapter_content_cache_port.dart';
import '../../services/book_cache_export_service.dart';

/// 将现有缓存导出服务适配到应用端口。
final class BookCacheExportPortAdapter implements BookCacheExportPort {
  BookCacheExportPortAdapter(ChapterContentCachePort contentCache)
    : _service = BookCacheExportService(contentCache: contentCache);

  final BookCacheExportService _service;

  @override
  Future<String> buildText({
    required Book book,
    required List<Chapter> chapters,
  }) {
    return _service.buildText(book: book, chapters: chapters);
  }

  @override
  Future<String> buildBooksText({
    required List<Book> books,
    required Future<List<Chapter>> Function(String bookId) loadChapters,
  }) {
    return _service.buildBooksText(books: books, loadChapters: loadChapters);
  }
}
