import '../../domain/source_subscription/rule_sub.dart';

/// 规则订阅偏好的应用层持久化边界。
abstract interface class RuleSubPrefsPort {
  List<RuleSub> get cached;

  Future<List<RuleSub>> load();

  Future<void> save(List<RuleSub> subs);

  Future<RuleSub?> findByUrl(String url);

  Future<int> maxOrder();

  Future<void> upsert(RuleSub sub);

  Future<void> delete(RuleSub sub);

  Future<void> updateAll(List<RuleSub> changed);
}
