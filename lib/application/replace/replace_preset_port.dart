import '../../domain/content/replace_rule.dart';
import 'replace_preset.dart';

/// 替换规则预置库访问端口。
abstract interface class ReplacePresetPort {
  /// 默认启动规则，区别于可供用户导入的完整预置库。
  List<ReplaceRule> builtInRules();

  List<ReplacePreset> get all;

  Map<String, List<ReplacePreset>> grouped();

  List<ReplaceRule> toRules(Iterable<ReplacePreset> presets);
}

/// 组合根尚未提供持久化实现时的安全空端口。
final class UnavailableReplacePresetPort implements ReplacePresetPort {
  const UnavailableReplacePresetPort();

  @override
  List<ReplaceRule> builtInRules() => const [];

  @override
  List<ReplacePreset> get all => const [];

  @override
  Map<String, List<ReplacePreset>> grouped() => const {};

  @override
  List<ReplaceRule> toRules(Iterable<ReplacePreset> presets) =>
      presets.map((preset) => preset.toRule()).toList();
}
