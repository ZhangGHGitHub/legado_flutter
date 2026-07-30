import '../../domain/content/replace_rule.dart';
import 'replace_preset.dart';

/// 替换规则预置库访问端口。
abstract interface class ReplacePresetPort {
  List<ReplacePreset> get all;

  Map<String, List<ReplacePreset>> grouped();

  List<ReplaceRule> toRules(Iterable<ReplacePreset> presets);
}
