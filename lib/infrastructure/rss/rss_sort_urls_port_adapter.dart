import '../../application/rss/rss_sort_urls_port.dart';
import '../../domain/rss/rss_source.dart';
import '../../services/rss_sort_urls.dart';

/// 将现有 RSS 分类 URL 服务适配到应用端口。
final class RssSortUrlsPortAdapter implements RssSortUrlsPort {
  const RssSortUrlsPortAdapter();

  @override
  Future<List<(String name, String url)>> resolve(RssSource source) {
    return RssSortUrls.resolve(source);
  }

  @override
  Future<void> clearCache(RssSource source) => RssSortUrls.clearCache(source);
}
