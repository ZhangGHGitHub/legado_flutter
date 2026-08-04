import '../../application/cache/cache_book_shelf_port.dart';
import '../../domain/book/book.dart';
import '../../domain/book/chapter.dart';

/// 以回调形式复用现有书架和本地章节事实源的缓存页适配器。
final class CacheBookShelfPortAdapter implements CacheBookShelfPort {
  const CacheBookShelfPortAdapter({
    required List<Book> Function() books,
    required Future<int> Function(String bookId) getChapterCount,
    required Future<List<Chapter>> Function(String bookId) getLocalChapters,
  }) : _books = books,
       _getChapterCount = getChapterCount,
       _getLocalChapters = getLocalChapters;

  final List<Book> Function() _books;
  final Future<int> Function(String bookId) _getChapterCount;
  final Future<List<Chapter>> Function(String bookId) _getLocalChapters;

  @override
  List<Book> get books => List<Book>.unmodifiable(_books());

  @override
  Future<int> getChapterCount(String bookId) => _getChapterCount(bookId);

  @override
  Future<List<Chapter>> getLocalChapters(String bookId) =>
      _getLocalChapters(bookId);
}
