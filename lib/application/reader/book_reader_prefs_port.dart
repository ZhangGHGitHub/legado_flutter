/// 单本书阅读配置的应用层持久化边界。
abstract interface class BookReaderPrefsPort {
  Future<int?> getPageAnim(String bookId);

  Future<void> setPageAnim(String bookId, int pageAnim);

  Future<bool> getReSegment(String bookId);

  Future<void> setReSegment(String bookId, bool value);
}
