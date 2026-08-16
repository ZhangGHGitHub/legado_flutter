import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/rss/rss_article.dart';
import 'package:legado_flutter/domain/rss/rss_source.dart';

void main() {
  group('RssArticle Freezed contract', () {
    const article = RssArticle(
      origin: 'source-url',
      sort: '默认',
      title: '文章标题',
      link: 'https://example.com/article',
      pubDate: '2026-08-02',
      description: '摘要',
      content: '正文',
      image: 'https://example.com/cover.jpg',
      group: '资讯',
      read: true,
      type: 2,
      durPos: 18,
    );

    test('preserves constructor fields and defaults', () {
      expect(article.origin, 'source-url');
      expect(article.sort, '默认');
      expect(article.title, '文章标题');
      expect(article.link, 'https://example.com/article');
      expect(article.pubDate, '2026-08-02');
      expect(article.description, '摘要');
      expect(article.content, '正文');
      expect(article.image, 'https://example.com/cover.jpg');
      expect(article.group, '资讯');
      expect(article.read, isTrue);
      expect(article.type, 2);
      expect(article.durPos, 18);

      const defaults = RssArticle(
        origin: 'source-url',
        title: '标题',
        link: 'https://example.com',
      );
      expect(defaults.sort, '');
      expect(defaults.group, '默认分组');
      expect(defaults.read, isFalse);
      expect(defaults.type, 0);
      expect(defaults.durPos, 0);
    });

    test('uses value equality and immutable copyWith', () {
      expect(article, equals(article.copyWith()));

      final updated = article.copyWith(content: null, read: false, durPos: 24);

      expect(updated.content, isNull);
      expect(updated.read, isFalse);
      expect(updated.durPos, 24);
      expect(updated.title, article.title);
      expect(article.content, '正文');
      expect(article.read, isTrue);
      expect(article.durPos, 18);
    });
  });

  group('RssSource Freezed contract', () {
    test('preserves legacy parsing, defaults, and unknown JSON fields', () {
      final source = RssSource.fromJson({
        'sourceUrl': 'https://example.com/rss',
        'sourceName': '示例源',
        'enabled': '1',
        'enabledCookieJar': 0,
        'enableJs': 'false',
        'lastUpdateTime': '1720000000000',
        'customOrder': 3.8,
        'type': 2,
        'loginUrl': null,
        'ruleArticles': 'article',
        'unknownField': {'kept': true},
      });

      expect(source.sourceUrl, 'https://example.com/rss');
      expect(source.sourceName, '示例源');
      expect(source.enabled, isTrue);
      expect(source.enabledCookieJar, isFalse);
      expect(source.enableJs, isFalse);
      expect(source.lastUpdateTime, 1720000000000);
      expect(source.customOrder, 0);
      expect(source.type, 2);
      expect(source.loginUrl, isNull);
      expect(source.ruleArticles, 'article');
      expect(source.raw['unknownField'], {'kept': true});

      final json = source.toJson();
      expect(json['unknownField'], {'kept': true});
      expect(json['sourceUrl'], 'https://example.com/rss');
      expect(json['enabled'], isTrue);
      expect(json.containsKey('loginUrl'), isTrue);
      expect(json['loginUrl'], isNull);
    });

    test('retains all fields through copyWith and supports value equality', () {
      final source = RssSource.fromJson({
        'sourceUrl': 'source-url',
        'sourceName': 'Source',
        'sourceComment': 'comment',
        'header': '{"User-Agent":"test"}',
        'loginUrl': 'https://example.com/login',
        'customOrder': 5,
        'rawOnly': 'preserve',
      });

      expect(source, equals(source.copyWith()));

      final updated = source.copyWith(
        sourceName: 'Updated',
        enabled: false,
        customOrder: 9,
      );

      expect(updated.sourceName, 'Updated');
      expect(updated.enabled, isFalse);
      expect(updated.customOrder, 9);
      expect(updated.sourceComment, 'comment');
      expect(updated.header, '{"User-Agent":"test"}');
      expect(updated.loginUrl, 'https://example.com/login');
      expect(updated.raw['rawOnly'], 'preserve');
      expect(source.sourceName, 'Source');
      expect(source.enabled, isTrue);
      expect(source.customOrder, 5);
    });

    test('keeps valid sources and filters invalid entries from JSON lists', () {
      final sources = RssSource.listFromJsonString('''[
        {"sourceUrl":"valid","sourceName":"Valid"},
        {"sourceUrl":"","sourceName":"Empty"},
        {"sourceName":"Missing URL"},
        "not-a-source"
      ]''');

      expect(sources, hasLength(1));
      expect(sources.single.sourceUrl, 'valid');
      expect(sources.single.sourceName, 'Valid');
    });
  });
}
