import '../../domain/source_subscription/rule_sub.dart';

/// 规则订阅创建和中文展示策略。
abstract final class RuleSubPolicy {
  static const typeLabels = ['书源', '订阅源', '替换规则'];

  static String typeLabel(int type) =>
      type >= 0 && type < typeLabels.length ? typeLabels[type] : typeLabels[0];

  static RuleSub decode(Map<String, dynamic> json, {DateTime Function()? now}) {
    return RuleSub.fromJson(json, fallbackId: _timestamp(now));
  }

  static RuleSub create({required int customOrder, DateTime Function()? now}) {
    final timestamp = _timestamp(now);
    return RuleSub(id: timestamp, customOrder: customOrder, update: timestamp);
  }

  static int _timestamp(DateTime Function()? now) =>
      (now ?? DateTime.now)().millisecondsSinceEpoch;
}

extension RuleSubPresentation on RuleSub {
  String get typeLabel => RuleSubPolicy.typeLabel(type);
}
