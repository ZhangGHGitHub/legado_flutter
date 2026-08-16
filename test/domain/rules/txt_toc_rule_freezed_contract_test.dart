import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/rules/txt_toc_rule.dart';

void main() {
  group('TxtTocRule Freezed contract', () {
    test('preserves defaults, JSON keys, fallback id, and copyWith', () {
      final rule = TxtTocRule.fromJson({
        'name': '测试',
        'rule': r'^第\\d+章',
      }, fallbackId: 42);

      expect(rule.id, 42);
      expect(rule.replacement, '');
      expect(rule.example, isNull);
      expect(rule.serialNumber, -1);
      expect(rule.enable, isTrue);
      expect(rule.toJson(), {
        'id': 42,
        'name': '测试',
        'rule': r'^第\\d+章',
        'replacement': '',
        'example': null,
        'serialNumber': -1,
        'enable': true,
      });

      final changed = rule.copyWith(
        replacement: '第',
        example: '第一章',
        serialNumber: 2,
        enable: false,
      );

      expect(changed.replacement, '第');
      expect(changed.example, '第一章');
      expect(changed.serialNumber, 2);
      expect(changed.enable, isFalse);
      expect(rule.replacement, '');
      expect(rule.example, isNull);
    });

    test('keeps legacy id-based identity equality', () {
      const first = TxtTocRule(id: 7, name: '第一条', rule: 'a');
      const second = TxtTocRule(id: 7, name: '第二条', rule: 'b', enable: false);

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first, isNot(const TxtTocRule(id: 8, name: '其他', rule: 'a')));
    });
  });
}
