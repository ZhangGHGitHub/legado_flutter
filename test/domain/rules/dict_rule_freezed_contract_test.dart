import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/rules/dict_rule.dart';

void main() {
  group('DictRule Freezed contract', () {
    test('preserves defaults, JSON keys, and immutable copyWith', () {
      const rule = DictRule(name: '测试');

      expect(rule.toJson(), {
        'name': '测试',
        'urlRule': '',
        'showRule': '',
        'enabled': true,
        'sortNumber': 0,
      });
      expect(DictRule.fromJson({'name': '测试'}), rule);

      final changed = rule.copyWith(
        urlRule: 'https://example.com?q={{key}}',
        showRule: 'body@all',
        enabled: false,
        sortNumber: 3,
      );

      expect(changed.urlRule, 'https://example.com?q={{key}}');
      expect(changed.showRule, 'body@all');
      expect(changed.enabled, isFalse);
      expect(changed.sortNumber, 3);
      expect(rule.urlRule, '');
      expect(rule.enabled, isTrue);
    });

    test('keeps legacy name-based identity equality', () {
      const first = DictRule(name: '同名', urlRule: 'a');
      const second = DictRule(name: '同名', urlRule: 'b', enabled: false);

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first, isNot(const DictRule(name: '另一条')));
    });
  });
}
