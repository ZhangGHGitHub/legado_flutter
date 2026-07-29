/// 正文净化和广告移除使用的替换规则领域实体。
class ReplaceRule {
  ReplaceRule({
    required this.id,
    required this.name,
    required this.pattern,
    this.replacement = '',
    this.isEnabled = true,
    this.isRegex = true,
  });

  final String id;
  final String name;
  final String pattern;
  final String replacement;
  final bool isEnabled;
  final bool isRegex;

  factory ReplaceRule.fromJson(Map<String, dynamic> json) => ReplaceRule(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    pattern: json['pattern'] as String,
    replacement: json['replacement'] as String? ?? '',
    isEnabled: json['isEnabled'] as bool? ?? true,
    isRegex: json['isRegex'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'pattern': pattern,
    'replacement': replacement,
    'isEnabled': isEnabled,
    'isRegex': isRegex,
  };
}
