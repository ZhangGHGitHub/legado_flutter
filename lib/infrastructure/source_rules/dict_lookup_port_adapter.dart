import '../../application/dictionary/dict_rule_tester.dart';
import '../../application/preferences/dict_rule_prefs_port.dart';
import '../../application/source_rules/dict_lookup_port.dart';
import '../../domain/ports/dict_rule_query_port.dart';
import '../../domain/rules/dict_rule.dart';

/// Composes persisted dictionary rules with the engine query port.
final class DictLookupPortAdapter implements DictLookupPort {
  DictLookupPortAdapter({
    required DictRulePrefsPort prefs,
    required DictRuleQueryPort queryPort,
  }) : _prefs = prefs,
       _tester = DictRuleTester(queryPort);

  final DictRulePrefsPort _prefs;
  final DictRuleTester _tester;

  @override
  Future<List<DictRule>> loadRules() => _prefs.load();

  @override
  Future<String> queryRule(DictRule rule, String word) =>
      _tester.test(rule, word);
}
