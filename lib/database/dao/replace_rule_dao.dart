import '../../domain/content/replace_rule.dart';
import '../../domain/repositories/replace_rule_repository.dart';
import '../database_helper.dart';

/// 替换规则 DAO — 只负责把领域端口转发到现有数据库适配器。
class ReplaceRuleDao implements ReplaceRuleRepository {
  ReplaceRuleDao([DatabaseHelper? db]) : _db = db ?? DatabaseHelper();

  final DatabaseHelper _db;

  @override
  Future<List<ReplaceRule>> getAll() => _db.getReplaceRules();

  @override
  Future<void> insert(ReplaceRule rule) => _db.insertReplaceRule(rule);

  @override
  Future<void> insertAll(List<ReplaceRule> rules) =>
      _db.insertReplaceRules(rules);

  @override
  Future<void> update(ReplaceRule rule) => _db.updateReplaceRule(rule);

  @override
  Future<void> toggle(String ruleId, bool enabled) =>
      _db.toggleReplaceRule(ruleId, enabled);

  @override
  Future<void> delete(String ruleId) => _db.deleteReplaceRule(ruleId);

  @override
  Future<void> clear() => _db.clearReplaceRules();
}
