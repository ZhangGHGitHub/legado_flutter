import 'dart:convert';

import '../../bridge/legado_engine_bridge.dart';
import '../../domain/ports/dict_rule_query_port.dart';
import '../../domain/rules/dict_rule.dart';
import '../../src/rust/api/dict.dart' as dict_api;

final class FrbDictRuleQueryPort implements DictRuleQueryPort {
  const FrbDictRuleQueryPort();

  @override
  Future<String> query(DictRule rule, String word) {
    if (!LegadoEngineBridge.isAvailable) {
      return Future<String>.error(StateError('Rust 引擎不可用，无法执行字典规则'));
    }
    return dict_api.queryDictRule(
      ruleJson: jsonEncode(rule.toJson()),
      word: word,
    );
  }
}
