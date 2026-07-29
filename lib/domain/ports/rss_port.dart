import 'package:legado_flutter/domain/rss/rss_source.dart';
import '../rss/rss_article.dart';

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
