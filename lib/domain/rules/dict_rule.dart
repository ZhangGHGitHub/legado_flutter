import 'package:freezed_annotation/freezed_annotation.dart';

part 'dict_rule.freezed.dart';

/// 字典规则领域实体，对齐 Legado `DictRule`。
@Freezed(equal: false, fromJson: false, toJson: false)
class DictRule with _$DictRule {
  const DictRule._();

  const factory DictRule({
    required String name,
    @Default('') String urlRule,
    @Default('') String showRule,
    @Default(true) bool enabled,
    @Default(0) int sortNumber,
  }) = _DictRule;

  factory DictRule.fromJson(Map<String, dynamic> json) => DictRule(
    name: json['name'] as String? ?? '',
    urlRule: json['urlRule'] as String? ?? '',
    showRule: json['showRule'] as String? ?? '',
    enabled: json['enabled'] as bool? ?? true,
    sortNumber: (json['sortNumber'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'urlRule': urlRule,
    'showRule': showRule,
    'enabled': enabled,
    'sortNumber': sortNumber,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DictRule && other.name == name;

  @override
  int get hashCode => name.hashCode;
}
