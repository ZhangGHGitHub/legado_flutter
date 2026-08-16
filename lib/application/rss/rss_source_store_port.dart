import '../../domain/rss/rss_source.dart';

/// RSS 订阅源列表的持久化边界。
abstract interface class RssSourceStorePort {
  Future<List<RssSource>> load();

  Future<void> save(List<RssSource> sources);
}

/// 组合根尚未提供持久化实现时的空端口。
final class UnavailableRssSourceStorePort implements RssSourceStorePort {
  const UnavailableRssSourceStorePort();

  @override
  Future<List<RssSource>> load() => Future.value(const []);

  @override
  Future<void> save(List<RssSource> sources) async {}
}
