import '../../domain/rules/txt_toc_rule.dart';

/// TXT 目录规则持久化端口。
abstract interface class TxtTocRulePrefsPort {
  List<TxtTocRule> get defaultRules;

  Future<List<TxtTocRule>> load();

  Future<void> save(List<TxtTocRule> rules);

  Future<void> resetToDefaults();
}
