import '../../domain/rules/dict_rule.dart';

/// 字典规则持久化端口。
abstract interface class DictRulePrefsPort {
  List<DictRule> get defaultRules;

  Future<List<DictRule>> load();

  Future<void> save(List<DictRule> rules);

  Future<void> resetToDefaults();
}
