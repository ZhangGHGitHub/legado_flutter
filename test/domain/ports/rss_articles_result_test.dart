import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/rss_port.dart';
import 'package:legado_flutter/domain/rss/rss_article.dart';

void main() {
  group('RssArticlesResult Freezed contract', () {
    const article = RssArticle(
      origin: 'https://example.com/rss',
      title: 'Article',
      link: 'https://example.com/article',
    );

    test('preserves articles and the optional next URL', () {
      const result = RssArticlesResult(
        articles: [article],
        nextUrl: 'https://example.com/page/2',
      );

      expect(result.articles, [article]);
      expect(result.nextUrl, 'https://example.com/page/2');
    });

    test('provides value equality and copyWith', () {
      const first = RssArticlesResult(articles: [article]);
      const second = RssArticlesResult(articles: [article]);

      expect(first, equals(second));
      expect(
        first.copyWith(nextUrl: 'https://example.com/page/2').nextUrl,
        'https://example.com/page/2',
      );
    });

    test('keeps the articles list read-only at the port boundary', () {
      const result = RssArticlesResult(articles: [article]);

      expect(() => result.articles.add(article), throwsUnsupportedError);
    });
  });
}
