import '../../domain/rss/rss_source.dart';

/// RSS 源编辑页的应用层持久化边界。
abstract interface class RssSourceEditPort {
  Future<void> save(RssSource source);
}
