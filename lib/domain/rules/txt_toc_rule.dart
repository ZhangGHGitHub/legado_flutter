/// TXT 目录解析规则领域实体，对齐 Legado `TxtTocRule`。
class TxtTocRule {
  const TxtTocRule({
    required this.id,
    required this.name,
    required this.rule,
    this.replacement = '',
    this.example,
    this.serialNumber = -1,
    this.enable = true,
  });

  final int id;
  final String name;
  final String rule;
  final String replacement;
  final String? example;
  final int serialNumber;
  final bool enable;

  TxtTocRule copyWith({
    int? id,
    String? name,
    String? rule,
    String? replacement,
    String? example,
    int? serialNumber,
    bool? enable,
  }) {
    return TxtTocRule(
      id: id ?? this.id,
      name: name ?? this.name,
      rule: rule ?? this.rule,
      replacement: replacement ?? this.replacement,
      example: example ?? this.example,
      serialNumber: serialNumber ?? this.serialNumber,
      enable: enable ?? this.enable,
    );
  }

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
