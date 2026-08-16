import '../../application/preferences/dict_rule_prefs_port.dart';
import '../../domain/rules/dict_rule.dart';
import '../../services/dict_rule_prefs.dart' as service;

/// 保留既有规则键名和默认规则的 SharedPreferences adapter。
final class SharedPreferencesDictRulePrefsAdapter implements DictRulePrefsPort {
  const SharedPreferencesDictRulePrefsAdapter();

  @override
  List<DictRule> get defaultRules => service.DictRulePrefs.defaultRules;

  @override
  Future<List<DictRule>> load() => service.DictRulePrefs.load();

  @override
  Future<void> save(List<DictRule> rules) => service.DictRulePrefs.save(rules);

  @override
  Future<void> resetToDefaults() => service.DictRulePrefs.resetToDefaults();
}
