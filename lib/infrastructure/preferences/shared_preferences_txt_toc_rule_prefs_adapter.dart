import '../../application/preferences/txt_toc_rule_prefs_port.dart';
import '../../domain/rules/txt_toc_rule.dart';
import '../../services/txt_toc_rule_prefs.dart' as service;

/// 保留既有规则键名和默认规则的 SharedPreferences adapter。
final class SharedPreferencesTxtTocRulePrefsAdapter
    implements TxtTocRulePrefsPort {
  const SharedPreferencesTxtTocRulePrefsAdapter();

  @override
  List<TxtTocRule> get defaultRules => service.TxtTocRulePrefs.defaultRules;

  @override
  Future<List<TxtTocRule>> load() => service.TxtTocRulePrefs.load();

  @override
  Future<void> save(List<TxtTocRule> rules) =>
      service.TxtTocRulePrefs.save(rules);

  @override
  Future<void> resetToDefaults() => service.TxtTocRulePrefs.resetToDefaults();
}
