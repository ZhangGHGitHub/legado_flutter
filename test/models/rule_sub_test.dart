import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/source_subscription/rule_sub_policy.dart';
import 'package:legado_flutter/domain/source_subscription/rule_sub.dart';

void main() {
  group('RuleSub model contract', () {
    test('new nullable fields default to null and preserve empty strings', () {
      const empty = RuleSub(id: 1, js: '', showRule: '', sourceUrl: '');
      const missing = RuleSub(id: 2);

      expect(empty.js, '');
      expect(empty.showRule, '');
      expect(empty.sourceUrl, '');
      expect(missing.js, isNull);
      expect(missing.showRule, isNull);
      expect(missing.sourceUrl, isNull);
    });

    test('fromJson keeps null and empty string values distinct', () {
      final rule = RuleSub.fromJson({
        'id': 7,
        'js': null,
        'showRule': '',
        'sourceUrl': 'https://example.com/source.json',
      });

      expect(rule.js, isNull);
      expect(rule.showRule, '');
      expect(rule.sourceUrl, 'https://example.com/source.json');
    });

    test('old JSON without new fields remains compatible', () {
      final rule = RuleSub.fromJson({
        'id': 8,
        'name': '旧订阅',
        'url': 'https://example.com/rules.json',
      });

      expect(rule.id, 8);
      expect(rule.name, '旧订阅');
      expect(rule.url, 'https://example.com/rules.json');
      expect(rule.js, isNull);
      expect(rule.showRule, isNull);
      expect(rule.sourceUrl, isNull);
    });

    test('application policy supplies the legacy timestamp id default', () {
      final rule = RuleSubPolicy.decode(const {
        'name': '无 ID 订阅',
      }, now: () => DateTime.fromMillisecondsSinceEpoch(123456));

      expect(rule.id, 123456);
      expect(rule.name, '无 ID 订阅');
    });

    test('application policy keeps type labels outside the entity', () {
      const rule = RuleSub(id: 11, type: 1);

      expect(rule.typeLabel, '订阅源');
      expect(RuleSubPolicy.typeLabel(99), '书源');
    });

    test('toJson and fromJson round-trip all fields', () {
      const original = RuleSub(
        id: 9,
        name: '完整订阅',
        url: 'https://example.com/rules.json',
        type: 1,
        customOrder: 3,
        autoUpdate: true,
        update: 123456,
        updateInterval: 12,
        silentUpdate: true,
        js: 'result.filter(Boolean)',
        showRule: 'body@text',
        sourceUrl: 'https://example.com/source',
      );

      expect(RuleSub.fromJson(original.toJson()).toJson(), original.toJson());
    });

    test('copyWith preserves, replaces, and clears nullable fields', () {
      const original = RuleSub(
        id: 10,
        js: 'old-js',
        showRule: 'old-rule',
        sourceUrl: 'old-source',
      );

      final updated = original.copyWith(
        js: '',
        showRule: null,
        sourceUrl: 'new-source',
      );
      final preserved = original.copyWith(name: 'changed');

      expect(updated.js, '');
      expect(updated.showRule, isNull);
      expect(updated.sourceUrl, 'new-source');
      expect(preserved.js, 'old-js');
      expect(preserved.showRule, 'old-rule');
      expect(preserved.sourceUrl, 'old-source');
    });
  });
}
