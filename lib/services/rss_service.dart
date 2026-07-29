import 'package:flutter/foundation.dart';

import '../domain/ports/rss_port.dart';
import '../domain/rss/rss_article.dart';
import 'package:legado_flutter/domain/rss/rss_source.dart';

/// RSS 服务 — 对齐 Jingshiro [Rss.kt] 调用链。
class RssService {
  RssService._();

  static RssPort? _rssPort;

  static void configureRssPort(RssPort port) {
    _rssPort = port;
  }

  @visibleForTesting
  static void resetRssPort() {
    _rssPort = null;
  }

  /// 对齐 Rss.getArticlesAwait
  static Future<({List<RssArticle> articles, String? nextUrl})> getArticles({
    required RssSource source,
    String sortName = '',
    String sortUrl = '',
    int page = 1,
  }) async {
    final rssPort = _rssPort;
    if (rssPort == null || !rssPort.isAvailable) {
      throw StateError('Rust 引擎不可用，无法拉取 RSS');
    }
    final result = await rssPort.getArticles(
      source: source,
      sortUrl: sortUrl,
      sortName: sortName.isEmpty ? source.sourceName : sortName,
      page: page,
    );
    debugPrint('[Rss] ${source.sourceName}: ${result.articles.length} 篇');
    return (articles: result.articles, nextUrl: result.nextUrl);
  }

  /// 对齐 Rss.getContentAwait
  static Future<String> getContent({
    required RssSource source,
    required RssArticle article,
  }) async {
    if (source.ruleContent.trim().isEmpty) {
      return article.content ?? article.description ?? '';
    }
    final rssPort = _rssPort;
    if (rssPort == null || !rssPort.isAvailable) {
      return article.content ?? article.description ?? '';
    }
    return rssPort.getContent(source: source, article: article);
  }
}
