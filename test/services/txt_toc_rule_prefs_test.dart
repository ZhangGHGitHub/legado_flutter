import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/rules/txt_toc_rule_creation_policy.dart';
import 'package:legado_flutter/domain/rules/txt_toc_rule.dart';
import 'package:legado_flutter/services/txt_toc_rule_prefs.dart';

void main() {
  test('defaultRules include 第x章 and Chapter presets', () {
    final names = TxtTocRulePrefs.defaultRules.map((r) => r.name).toList();
    expect(names.any((n) => n.contains('目录')), isTrue);
    expect(names.any((n) => n.contains('Chapter')), isTrue);
    expect(
      TxtTocRulePrefs.defaultRules.any((r) => r.enable && r.rule.isNotEmpty),
      isTrue,
    );
  });

  test('TxtTocRule json round-trip', () {
    final rule = TxtTocRule(
      id: 42,
      name: '测试',
      rule: r'^第\d+章',
      replacement: '',
      example: '第一章',
      serialNumber: 3,
      enable: false,
    );
    final again = TxtTocRule.fromJson(rule.toJson());
    expect(again.id, 42);
    expect(again.name, '测试');
    expect(again.rule, r'^第\d+章');
    expect(again.example, '第一章');
    expect(again.serialNumber, 3);
    expect(again.enable, isFalse);
  });

  test('creation policy supplies and preserves timestamp ids', () {
    final decoded = TxtTocRuleCreationPolicy.decode(const {
      'name': '旧规则',
      'rule': '^旧章',
    }, now: () => DateTime.fromMillisecondsSinceEpoch(321));
    final edited = TxtTocRuleCreationPolicy.fromEditor(
      existing: decoded,
      name: '新规则',
      rule: '^新章',
      replacement: '',
      example: null,
      now: () => DateTime.fromMillisecondsSinceEpoch(999),
    );

    expect(decoded.id, 321);
    expect(decoded.serialNumber, -1);
    expect(decoded.enable, isTrue);
    expect(edited.id, 321);
  });
}
