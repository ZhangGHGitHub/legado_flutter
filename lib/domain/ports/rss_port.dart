import '../../models/rss_article.dart';
import '../../models/rss_source.dart';

class RssArticlesResult {
  const RssArticlesResult({required this.articles, this.nextUrl});

  final List<RssArticle> articles;
  final String? nextUrl;
}

abstract interface class RssPort {
  bool get isAvailable;

  Future<RssArticlesResult> getArticles({
    required RssSource source,
    required String sortName,
    required String sortUrl,
    required int page,
  });

  Future<String> getContent({
    required RssSource source,
    required RssArticle article,
  });
}
