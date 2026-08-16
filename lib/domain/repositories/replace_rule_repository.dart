import '../content/replace_rule.dart';

/// 替换规则领域存储端口。
///
/// Provider 和应用层只依赖这个契约；SQLite/Rust 适配器可以替换，
/// 而不会把数据库实现扩散到规则管理页面。
abstract interface class ReplaceRuleRepository {
  Future<List<ReplaceRule>> getAll();

  Future<void> insert(ReplaceRule rule);

  Future<void> insertAll(List<ReplaceRule> rules);

  Future<void> update(ReplaceRule rule);

  Future<void> toggle(String ruleId, bool enabled);

  Future<void> delete(String ruleId);

  Future<void> clear();
}
