/// RSS 文章已读链接的持久化边界。
abstract interface class RssReadStatePort {
  Future<Set<String>> read(String sourceUrl);

  Future<void> write(String sourceUrl, Iterable<String> links);
}
