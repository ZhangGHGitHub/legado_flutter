import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/source_subscription/rule_sub_import_port.dart';
import 'package:legado_flutter/domain/content/replace_rule.dart';
import 'package:legado_flutter/domain/rss/rss_source.dart';
import 'package:legado_flutter/domain/source/book_source.dart';

void main() {
  group('RuleSubImportResult', () {
    test('keeps book-source order, names, and kind-specific count', () {
      final result = RuleSubImportResult.bookSources([
        const BookSource(
          bookSourceUrl: 'https://first.example',
          bookSourceName: '第一个书源',
        ),
        const BookSource(
          bookSourceUrl: 'https://second.example',
          bookSourceName: '第二个书源',
        ),
      ]);

      expect(result.kind, RuleSubImportKind.bookSource);
      expect(result.count, 2);
      expect(result.labels, ['第一个书源', '第二个书源']);
      expect(result.bookSources.map((source) => source.bookSourceUrl), [
        'https://first.example',
        'https://second.example',
      ]);
      expect(result.rssSources, isEmpty);
      expect(result.replaceRules, isEmpty);
    });

    test('keeps RSS order, names, and kind-specific count', () {
      final result = RuleSubImportResult.rssSources([
        const RssSource(
          sourceUrl: 'https://first.example/rss',
          sourceName: '第一个 RSS',
        ),
        const RssSource(
          sourceUrl: 'https://second.example/rss',
          sourceName: '第二个 RSS',
        ),
      ]);

      expect(result.kind, RuleSubImportKind.rssSource);
      expect(result.count, 2);
      expect(result.labels, ['第一个 RSS', '第二个 RSS']);
      expect(result.rssSources.map((source) => source.sourceUrl), [
        'https://first.example/rss',
        'https://second.example/rss',
      ]);
      expect(result.bookSources, isEmpty);
      expect(result.replaceRules, isEmpty);
    });

    test('uses pattern only when a replacement-rule name is empty', () {
      final result = RuleSubImportResult.replaceRules([
        const ReplaceRule(id: 'named', name: '具名规则', pattern: 'named'),
        const ReplaceRule(id: 'fallback', name: '', pattern: '回退模式'),
      ]);

      expect(result.kind, RuleSubImportKind.replaceRule);
      expect(result.count, 2);
      expect(result.labels, ['具名规则', '回退模式']);
      expect(result.replaceRules.map((rule) => rule.id), ['named', 'fallback']);
      expect(result.bookSources, isEmpty);
      expect(result.rssSources, isEmpty);
    });

    test('has Freezed value equality without changing the factory API', () {
      final first = RuleSubImportResult.bookSources([
        const BookSource(
          bookSourceUrl: 'https://source.example',
          bookSourceName: '书源',
        ),
      ]);
      final second = RuleSubImportResult.bookSources([
        const BookSource(
          bookSourceUrl: 'https://source.example',
          bookSourceName: '书源',
        ),
      ]);

      expect(first, second);
      expect(
        first.copyWith(kind: RuleSubImportKind.rssSource).kind,
        RuleSubImportKind.rssSource,
      );
    });
  });
}
