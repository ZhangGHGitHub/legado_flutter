/// 字典规则 — 对齐 Jingshiro [DictRule]
class DictRule {
  final String name;
  final String urlRule;
  final String showRule;
  final bool enabled;
  final int sortNumber;

  const DictRule({
    required this.name,
    this.urlRule = '',
    this.showRule = '',
    this.enabled = true,
    this.sortNumber = 0,
  });

  DictRule copyWith({
    String? name,
    String? urlRule,
    String? showRule,
    bool? enabled,
    int? sortNumber,
  }) {
    return DictRule(
      name: name ?? this.name,
      urlRule: urlRule ?? this.urlRule,
      showRule: showRule ?? this.showRule,
      enabled: enabled ?? this.enabled,
      sortNumber: sortNumber ?? this.sortNumber,
    );
  }

  factory DictRule.fromJson(Map<String, dynamic> json) {
    return DictRule(
      name: json['name'] as String? ?? '',
      urlRule: json['urlRule'] as String? ?? '',
      showRule: json['showRule'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
      sortNumber: (json['sortNumber'] as num?)?.toInt() ?? 0,
    );
  }

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
