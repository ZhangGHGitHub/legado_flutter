/// 替换规则模型 - 用于内容净化和广告去除
class ReplaceRule {
  final String id;
  final String name;        // 规则名称
  final String pattern;     // 正则表达式
  final String replacement; // 替换为
  final bool isEnabled;     // 是否启用
  final bool isRegex;       // 是否为正则（否则普通文本）

  ReplaceRule({
    required this.id,
    required this.name,
    required this.pattern,
    this.replacement = '',
    this.isEnabled = true,
    this.isRegex = true,
  });

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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'pattern': pattern,
    'replacement': replacement,
    'isEnabled': isEnabled,
    'isRegex': isRegex,
  };
}
