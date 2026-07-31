import '../../domain/rss/rss_article.dart';

/// RSS 收藏列表的读写边界。
abstract interface class RssStarPrefsPort {
  Future<List<RssArticle>> loadAll();

  Future<void> remove(String origin, String link);
}
