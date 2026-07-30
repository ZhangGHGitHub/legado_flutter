import '../../domain/content/replace_rule.dart';

/// 可导入的替换规则预设。
final class ReplacePreset {
  const ReplacePreset({
    required this.id,
    required this.category,
    required this.name,
    required this.pattern,
    this.replacement = '',
    this.isRegex = true,
  });

  final String id;
  final String category;
  final String name;
  final String pattern;
  final String replacement;
  final bool isRegex;

  ReplaceRule toRule({bool enabled = true}) => ReplaceRule(
    id: 'preset_$id',
    name: name,
    pattern: pattern,
    replacement: replacement,
    isRegex: isRegex,
    isEnabled: enabled,
  );
}
