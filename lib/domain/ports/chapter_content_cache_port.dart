/// 章节正文文件缓存端口。
///
/// 文件布局和缓存错误处理由 infrastructure 适配器提供；调用方只依赖
/// 章节正文的读取、写入和删除契约。
abstract interface class ChapterContentCachePort {
  Future<String?> get(String bookId, String chapterId);

  Future<void> save(String bookId, String chapterId, String content);

  Future<void> delete(String bookId, String chapterId);

  Future<void> clearAll();

  Future<void> clearBook(String bookId);

  Future<int> clearInvalid(Set<String> validBookIds);

  Future<bool> has(String bookId, String chapterId);

  Future<Set<String>> listChapterIds(String bookId);

  String sanitizeChapterId(String chapterId);

  Future<Map<String, int>> mapWordCounts(
    String bookId, {
    Set<String>? chapterIds,
  });

  Future<({int bytes, int chapterFiles})> stats(String bookId);
}
