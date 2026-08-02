import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/content/replace_rule.dart';

void main() {
  group('ReplaceRule Freezed contract', () {
    test('preserves legacy JSON defaults and supports immutable copyWith', () {
      final parsed = ReplaceRule.fromJson({
        'id': 'rule-1',
        'pattern': '广告',
      });

      expect(
        parsed,
        ReplaceRule(id: 'rule-1', name: '', pattern: '广告'),
      );
      expect(parsed.replacement, '');
      expect(parsed.isEnabled, isTrue);
      expect(parsed.isRegex, isTrue);

      final disabled = parsed.copyWith(
        replacement: '正文',
        isEnabled: false,
      );

      expect(disabled.id, 'rule-1');
      expect(disabled.replacement, '正文');
      expect(disabled.isEnabled, isFalse);
      expect(parsed.isEnabled, isTrue);
      expect(
        disabled.toJson(),
        {
          'id': 'rule-1',
          'name': '',
          'pattern': '广告',
          'replacement': '正文',
          'isEnabled': false,
          'isRegex': true,
        },
      );
    });
  });
}
