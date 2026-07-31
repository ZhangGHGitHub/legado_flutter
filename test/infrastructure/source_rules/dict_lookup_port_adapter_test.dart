import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/preferences/dict_rule_prefs_port.dart';
import 'package:legado_flutter/domain/ports/dict_rule_query_port.dart';
import 'package:legado_flutter/domain/rules/dict_rule.dart';
import 'package:legado_flutter/infrastructure/source_rules/dict_lookup_port_adapter.dart';

final class _FakeDictPrefs implements DictRulePrefsPort {
  final rules = [
    const DictRule(name: '测试', urlRule: 'https://example.com?q={{key}}'),
  ];

  @override
  List<DictRule> get defaultRules => rules;

  @override
  Future<List<DictRule>> load() async => rules;

  @override
  Future<void> resetToDefaults() async {}

  @override
  Future<void> save(List<DictRule> rules) async {}
}

final class _FakeDictQuery implements DictRuleQueryPort {
  DictRule? rule;
  String? word;

  @override
  Future<String> query(DictRule rule, String word) async {
    this.rule = rule;
    this.word = word;
    return '结果';
  }
}

void main() {
  test('loads rules and preserves dictionary query validation', () async {
    final query = _FakeDictQuery();
    final adapter = DictLookupPortAdapter(
      prefs: _FakeDictPrefs(),
      queryPort: query,
    );
    final rule = (await adapter.loadRules()).single;

    expect(await adapter.queryRule(rule, '  词  '), '结果');
    expect(query.rule, same(rule));
    expect(query.word, '词');
    expect(() => adapter.queryRule(rule, '  '), throwsA(isA<ArgumentError>()));
  });
}
