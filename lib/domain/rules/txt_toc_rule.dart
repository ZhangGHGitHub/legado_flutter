import 'package:freezed_annotation/freezed_annotation.dart';

part 'txt_toc_rule.freezed.dart';

/// TXT 目录解析规则领域实体，对齐 Legado `TxtTocRule`。
@Freezed(equal: false, fromJson: false, toJson: false)
class TxtTocRule with _$TxtTocRule {
  const TxtTocRule._();

  const factory TxtTocRule({
    required int id,
    required String name,
    required String rule,
    @Default('') String replacement,
    String? example,
    @Default(-1) int serialNumber,
    @Default(true) bool enable,
  }) = _TxtTocRule;

  factory TxtTocRule.fromJson(Map<String, dynamic> json, {int fallbackId = 0}) {
    return TxtTocRule(
      id: (json['id'] as num?)?.toInt() ?? fallbackId,
      name: json['name'] as String? ?? '',
      rule: json['rule'] as String? ?? '',
      replacement: json['replacement'] as String? ?? '',
      example: json['example'] as String?,
      serialNumber: (json['serialNumber'] as num?)?.toInt() ?? -1,
      enable: json['enable'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'rule': rule,
    'replacement': replacement,
    'example': example,
    'serialNumber': serialNumber,
    'enable': enable,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TxtTocRule && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
