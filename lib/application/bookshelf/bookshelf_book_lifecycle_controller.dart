import '../../domain/book/book.dart';
import '../../domain/ports/chapter_content_cache_port.dart';
import '../../domain/repositories/book_repository.dart';

/// 书架书籍新增和删除的 application 写入控制器。
///
/// Provider 继续负责书架列表、未读元数据和通知；本控制器只固定仓储与
/// 章节缓存副作用的顺序，确保所有书架写入入口使用同一 application 边界。
final class BookshelfBookLifecycleController {
  BookshelfBookLifecycleController({
    required BookRepository repository,
    required ChapterContentCachePort contentCache,
  }) : _repository = repository,
       _contentCache = contentCache;

  final BookRepository _repository;
  final ChapterContentCachePort _contentCache;

  Future<void> addBook(Book book) => _repository.insert(book);

  /// 删除书籍并清理该书的章节缓存。
  Future<void> removeBook(String bookId) async {
    await _repository.delete(bookId);
    await _contentCache.clearBook(bookId);
  }
}
