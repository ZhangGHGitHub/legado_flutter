import '../../domain/ports/chapter_content_cache_port.dart';
import '../../help/book_help.dart';

/// 基于 [BookHelp] 文件缓存的章节正文适配器。
class FileChapterContentCache implements ChapterContentCachePort {
  const FileChapterContentCache();

  @override
  Future<String?> get(String bookId, String chapterId) {
    return BookHelp.getCachedContent(bookId, chapterId);
  }

  @override
  Future<void> save(String bookId, String chapterId, String content) {
    return BookHelp.saveContent(bookId, chapterId, content);
  }

  @override
  Future<void> delete(String bookId, String chapterId) {
    return BookHelp.deleteChapterContent(bookId, chapterId);
  }

  @override
  Future<void> clearAll() => BookHelp.clearAllCache();

  @override
  Future<void> clearBook(String bookId) => BookHelp.clearBookCache(bookId);

  @override
  Future<int> clearInvalid(Set<String> validBookIds) {
    return BookHelp.clearInvalidCache(validBookIds);
  }

  @override
  Future<bool> has(String bookId, String chapterId) {
    return BookHelp.hasCachedContent(bookId, chapterId);
  }

  @override
  Future<Set<String>> listChapterIds(String bookId) {
    return BookHelp.listCachedChapterIds(bookId);
  }

  @override
  String sanitizeChapterId(String chapterId) {
    return BookHelp.sanitizeId(chapterId);
  }

  @override
  Future<Map<String, int>> mapWordCounts(
    String bookId, {
    Set<String>? chapterIds,
  }) {
    return BookHelp.mapCachedWordCounts(bookId, chapterIds: chapterIds);
  }

  @override
  Future<({int bytes, int chapterFiles})> stats(String bookId) {
    return BookHelp.bookCacheStats(bookId);
  }
}
