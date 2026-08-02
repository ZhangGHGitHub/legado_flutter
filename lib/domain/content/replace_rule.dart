import 'package:freezed_annotation/freezed_annotation.dart';

part 'replace_rule.freezed.dart';

/// 正文净化和广告移除使用的替换规则领域实体。
@freezed
class ReplaceRule with _$ReplaceRule {
  const ReplaceRule._();

  const factory ReplaceRule({
    required String id,
    required String name,
    required String pattern,
    @Default('') String replacement,
    @Default(true) bool isEnabled,
    @Default(true) bool isRegex,
  }) = _ReplaceRule;

  factory ReplaceRule.fromJson(Map<String, dynamic> json) {
    return ReplaceRule(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      pattern: json['pattern'] as String,
      replacement: json['replacement'] as String? ?? '',
      isEnabled: json['isEnabled'] as bool? ?? true,
      isRegex: json['isRegex'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'pattern': pattern,
      'replacement': replacement,
      'isEnabled': isEnabled,
      'isRegex': isRegex,
    };
  }
}
