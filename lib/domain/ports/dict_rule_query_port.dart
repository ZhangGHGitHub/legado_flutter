import '../rules/dict_rule.dart';

/// 执行完整 AnalyzeUrl 和 showRule 的字典查询端口。
abstract interface class DictRuleQueryPort {
  Future<String> query(DictRule rule, String word);
}
