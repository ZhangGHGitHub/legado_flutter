import '../../bridge/legado_engine_bridge.dart';
import '../../domain/ports/rss_port.dart';
import '../../domain/rss/rss_article.dart';
import 'package:legado_flutter/domain/rss/rss_source.dart';
import 'app_error_message.dart';
import '../../src/rust/api.dart' as rust_api;

class FrbRssPort implements RssPort {
  @override
  bool get isAvailable => LegadoEngineBridge.isAvailable;

  @override
  Future<RssArticlesResult> getArticles({
    required RssSource source,
    required String sortName,
    required String sortUrl,
    required int page,
  }) async {
    if (!isAvailable) {
      throw StateError('Rust 引擎不可用，无法拉取 RSS');
    }
    try {
      final result = await rust_api.getRssArticles(
        sourceJson: source.toEngineJson(),
        sortUrl: sortUrl,
        sortName: sortName,
        page: page,
      );
      return RssArticlesResult(
        articles: result.articles
            .map(
              (article) => RssArticle(
                origin: article.origin.isEmpty
                    ? source.sourceUrl
                    : article.origin,
                sort: article.sort,
                title: article.title,
                link: article.link,
                pubDate: article.pubDate.isEmpty ? null : article.pubDate,
                description: article.description.isEmpty
                    ? null
                    : article.description,
                content: article.content.isEmpty ? null : article.content,
                image: article.image.isEmpty ? null : article.image,
                type: source.type,
              ),
            )
            .toList(growable: false),
        nextUrl: result.nextUrl,
      );
    } catch (error) {
      final message = appErrorMessage(error);
      if (message != null) throw RssPortException(message);
      rethrow;
    }
  }

  @override
  Future<String> getContent({
    required RssSource source,
    required RssArticle article,
  }) async {
    if (!isAvailable) {
      return Future<String>.error(StateError('Rust 引擎不可用，无法拉取 RSS 正文'));
    }
    try {
      return await rust_api.getRssContent(
        sourceJson: source.toEngineJson(),
        articleLink: article.link,
      );
    } catch (error) {
      final message = appErrorMessage(error);
      if (message != null) throw RssPortException(message);
      rethrow;
    }
  }
}
