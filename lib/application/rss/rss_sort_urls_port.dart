import '../../domain/rss/rss_source.dart';

/// RSS 分类 URL 解析与缓存清理的应用边界。
abstract interface class RssSortUrlsPort {
  Future<List<(String name, String url)>> resolve(RssSource source);

  Future<void> clearCache(RssSource source);
}
