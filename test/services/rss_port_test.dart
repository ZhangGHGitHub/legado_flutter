import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/rss_port.dart';
import 'package:legado_flutter/domain/rss/rss_article.dart';
import 'package:legado_flutter/domain/rss/rss_source.dart';
import 'package:legado_flutter/services/rss_service.dart';

class _FakeRssPort implements RssPort {
  _FakeRssPort({this.available = true});

  final bool available;
  final calls = <String>[];

  @override
  bool get isAvailable => available;

  @override
  Future<RssArticlesResult> getArticles({
    required RssSource source,
    required String sortName,
    required String sortUrl,
    required int page,
  }) async {
    calls.add('articles:$sortName:$sortUrl:$page');
    return RssArticlesResult(
      articles: [
        RssArticle(
          origin: source.sourceUrl,
          title: '文章',
          link: 'https://example.com/article',
          type: source.type,
        ),
      ],
      nextUrl: 'https://example.com/next',
    );
  }

  @override
  Future<String> getContent({
    required RssSource source,
    required RssArticle article,
  }) async {
    calls.add('content:${article.link}');
    return '正文';
  }
}

void main() {
  const source = RssSource(
    sourceUrl: 'https://example.com/rss',
    sourceName: '测试 RSS',
    ruleContent: 'content',
  );
  const article = RssArticle(
    origin: 'https://example.com/rss',
    title: '文章',
    link: 'https://example.com/article',
  );

  tearDown(RssService.resetRssPort);

  test('reset clears the configured RSS port', () async {
    RssService.configureRssPort(_FakeRssPort());
    RssService.resetRssPort();

    await expectLater(RssService.getArticles(source: source), throwsStateError);
  });

  test(
    'RssService forwards article and content calls through the port',
    () async {
      final port = _FakeRssPort();
      RssService.configureRssPort(port);

      final result = await RssService.getArticles(source: source, page: 2);
      final content = await RssService.getContent(
        source: source,
        article: article,
      );

      expect(result.articles.single.title, '文章');
      expect(result.nextUrl, 'https://example.com/next');
      expect(content, '正文');
      expect(port.calls, [
        'articles:测试 RSS::2',
        'content:https://example.com/article',
      ]);
    },
  );

  test(
    'content falls back to article text when the source has no rule',
    () async {
      final port = _FakeRssPort(available: false);
      RssService.configureRssPort(port);
      const noRule = RssSource(
        sourceUrl: 'https://example.com/rss',
        sourceName: '测试 RSS',
      );
      const fallback = RssArticle(
        origin: 'https://example.com/rss',
        title: '文章',
        link: 'https://example.com/article',
        content: '缓存正文',
      );

      expect(
        await RssService.getContent(source: noRule, article: fallback),
        '缓存正文',
      );
      expect(port.calls, isEmpty);
    },
  );
}
