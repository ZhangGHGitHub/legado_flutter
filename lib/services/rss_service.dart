import 'package:flutter/foundation.dart';

import '../bridge/legado_engine_bridge.dart';
import '../models/rss_article.dart';
import '../models/rss_source.dart';
import '../src/rust/api.dart' as rust_api;

/// RSS 服务 — 对齐 Jingshiro [Rss.kt] 调用链。
class RssService {
  RssService._();

  /// 对齐 Rss.getArticlesAwait
  static Future<({List<RssArticle> articles, String? nextUrl})> getArticles({
    required RssSource source,
    String sortName = '',
    String sortUrl = '',
    int page = 1,
  }) async {
    if (!LegadoEngineBridge.isAvailable) {
      throw StateError('Rust 引擎不可用，无法拉取 RSS');
    }
    final result = await rust_api.getRssArticles(
      sourceJson: source.toEngineJson(),
      sortUrl: sortUrl,
      sortName: sortName.isEmpty ? source.sourceName : sortName,
      page: page,
    );
    final articles = result.articles
        .map(
          (a) => RssArticle(
            origin: a.origin.isEmpty ? source.sourceUrl : a.origin,
            sort: a.sort,
            title: a.title,
            link: a.link,
            pubDate: a.pubDate.isEmpty ? null : a.pubDate,
            description: a.description.isEmpty ? null : a.description,
            content: a.content.isEmpty ? null : a.content,
            image: a.image.isEmpty ? null : a.image,
            type: source.type,
          ),
        )
        .toList();
    debugPrint('[Rss] ${source.sourceName}: ${articles.length} 篇');
    return (articles: articles, nextUrl: result.nextUrl);
  }

  /// 对齐 Rss.getContentAwait
  static Future<String> getContent({
    required RssSource source,
    required RssArticle article,
  }) async {
    if (source.ruleContent.trim().isEmpty) {
      return article.content ?? article.description ?? '';
    }
    if (!LegadoEngineBridge.isAvailable) {
      return article.content ?? article.description ?? '';
    }
    return rust_api.getRssContent(
      sourceJson: source.toEngineJson(),
      articleLink: article.link,
    );
  }
}
