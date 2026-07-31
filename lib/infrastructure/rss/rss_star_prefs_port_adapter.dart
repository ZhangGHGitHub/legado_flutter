import '../../application/rss/rss_star_prefs_port.dart';
import '../../domain/rss/rss_article.dart';
import '../../services/rss_star_prefs.dart';

/// 将现有 RSS 收藏偏好服务适配到应用端口。
final class RssStarPrefsPortAdapter implements RssStarPrefsPort {
  const RssStarPrefsPortAdapter();

  @override
  Future<List<RssArticle>> loadAll() => RssStarPrefs.loadAll();

  @override
  Future<void> remove(String origin, String link) =>
      RssStarPrefs.remove(origin, link);
}
