import '../../application/source_subscription/rule_sub_prefs_port.dart';
import '../../domain/source_subscription/rule_sub.dart';
import '../../services/rule_sub_prefs.dart' as service;

/// 保留既有规则订阅键名、默认值和 JSON 读写语义的 SharedPreferences adapter。
final class SharedPreferencesRuleSubPrefsAdapter implements RuleSubPrefsPort {
  const SharedPreferencesRuleSubPrefsAdapter();

  @override
  List<RuleSub> get cached => service.RuleSubPrefs.cached;

  @override
  Future<List<RuleSub>> load() => service.RuleSubPrefs.load();

  @override
  Future<void> save(List<RuleSub> subs) => service.RuleSubPrefs.save(subs);

  @override
  Future<RuleSub?> findByUrl(String url) => service.RuleSubPrefs.findByUrl(url);

  @override
  Future<int> maxOrder() => service.RuleSubPrefs.maxOrder();

  @override
  Future<void> upsert(RuleSub sub) => service.RuleSubPrefs.upsert(sub);

  @override
  Future<void> delete(RuleSub sub) => service.RuleSubPrefs.delete(sub);

  @override
  Future<void> updateAll(List<RuleSub> changed) =>
      service.RuleSubPrefs.updateAll(changed);
}
