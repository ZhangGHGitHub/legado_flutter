import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';

/// 书架与章节的领域存储端口。
///
/// 页面和 Provider 只依赖这个契约；SQLite、Rust FRB 或测试内存实现
/// 都可以作为具体适配器接入。
abstract interface class BookRepository {
  Future<void> insert(Book book);

  Future<List<Book>> getAll();

  Future<void> updateProgress(
    String bookId,
    double progress,
    String? chapter, {
    int pageIndex,
  });

  Future<void> delete(String bookId);

  Future<void> updateCover(String bookId, String coverUrl);

  Future<void> updateBookDetails(
    String bookId,
    String name,
    String author,
    String description,
  );

  Future<void> updateGroup(String bookId, String group);

  Future<void> insertChapters(List<Chapter> chapters);

  Future<List<Chapter>> getChapters(String bookId);

  Future<String?> getChapterContent(String chapterId);

  Future<void> saveChapterContent(String chapterId, String content);

  Future<void> clearChapterContent(Chapter chapter);
}
