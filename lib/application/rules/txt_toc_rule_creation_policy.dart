import '../../domain/rules/txt_toc_rule.dart';

/// TXT 目录规则的时间戳 ID 创建策略。
abstract final class TxtTocRuleCreationPolicy {
  static TxtTocRule decode(
    Map<String, dynamic> json, {
    DateTime Function()? now,
  }) {
    return TxtTocRule.fromJson(json, fallbackId: _timestamp(now));
  }

  static TxtTocRule fromEditor({
    required String name,
    required String rule,
    required String replacement,
    required String? example,
    TxtTocRule? existing,
    DateTime Function()? now,
  }) {
    return TxtTocRule(
      id: existing?.id ?? _timestamp(now),
      name: name,
      rule: rule,
      replacement: replacement,
      example: example,
      serialNumber: existing?.serialNumber ?? -1,
      enable: existing?.enable ?? true,
    );
  }

  static int _timestamp(DateTime Function()? now) =>
      (now ?? DateTime.now)().millisecondsSinceEpoch;
}
