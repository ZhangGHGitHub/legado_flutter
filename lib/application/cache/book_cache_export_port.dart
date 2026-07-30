import '../../domain/book/book.dart';
import '../../domain/book/chapter.dart';

/// 书籍缓存正文导出能力。
abstract interface class BookCacheExportPort {
  Future<String> buildText({
    required Book book,
    required List<Chapter> chapters,
  });

  Future<String> buildBooksText({
    required List<Book> books,
    required Future<List<Chapter>> Function(String bookId) loadChapters,
  });
}
