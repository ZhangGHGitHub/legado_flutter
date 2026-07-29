import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/dictionary/dict_rule_tester.dart';
import 'package:legado_flutter/domain/ports/dict_rule_query_port.dart';
import 'package:legado_flutter/domain/rules/dict_rule.dart';
import 'package:legado_flutter/services/dict_rule_prefs.dart';

final class _FakeDictRuleQueryPort implements DictRuleQueryPort {
  String result = '';
  DictRule? rule;
  String? word;

  @override
  Future<String> query(DictRule rule, String word) async {
    this.rule = rule;
    this.word = word;
    return result;
  }
}

void main() {
  test('defaultRules include 海词 and 有道', () {
    final names = DictRulePrefs.defaultRules.map((r) => r.name).toList();
    expect(names, contains('海词英文'));
    expect(names, contains('有道'));
    expect(names, contains('百度汉语'));
    expect(
      DictRulePrefs.defaultRules.any((r) => r.enabled && r.urlRule.isNotEmpty),
      isTrue,
    );
  });

  test('DictRule json round-trip', () {
    final rule = DictRule(
      name: '测试',
      urlRule: 'https://example.com?q={{key}}',
      showRule: 'tag.body@all',
      enabled: false,
      sortNumber: 3,
    );
    final again = DictRule.fromJson(rule.toJson());
    expect(again.name, '测试');
    expect(again.urlRule, 'https://example.com?q={{key}}');
    expect(again.showRule, 'tag.body@all');
    expect(again.enabled, isFalse);
    expect(again.sortNumber, 3);
  });

  test('DictRuleTester rejects empty word and delegates JS rules', () async {
    final port = _FakeDictRuleQueryPort()..result = '完整 JS 结果';
    final tester = DictRuleTester(port);
    expect(
      () => tester.test(
        const DictRule(name: 'x', urlRule: 'https://example.com'),
        '  ',
      ),
      throwsA(isA<ArgumentError>()),
    );
    final result = await tester.test(
      const DictRule(name: 'js', urlRule: '@js: return 1'),
      ' 词 ',
    );
    expect(result, '完整 JS 结果');
    expect(port.rule?.name, 'js');
    expect(port.word, '词');
  });

  test('DictRuleTester blocks SSRF hosts', () async {
    final port = _FakeDictRuleQueryPort();
    final tester = DictRuleTester(port);
    expect(
      () => tester.test(
        const DictRule(name: 'bad', urlRule: 'http://127.0.0.1/dict?q={{key}}'),
        'test',
      ),
      throwsA(isA<FormatException>()),
    );
    expect(port.rule, isNull);
  });
}
