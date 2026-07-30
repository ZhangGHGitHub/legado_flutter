import '../../application/replace/replace_preset.dart';
import '../../application/replace/replace_preset_port.dart';
import '../../domain/content/replace_rule.dart';
import '../../services/replace_preset_library.dart' as legacy;

/// 将现有替换规则预置库适配到应用端口。
final class ReplacePresetPortAdapter implements ReplacePresetPort {
  const ReplacePresetPortAdapter();

  @override
  List<ReplacePreset> get all => legacy.ReplacePresetLibrary.all
      .map(_fromServicePreset)
      .toList(growable: false);

  @override
  Map<String, List<ReplacePreset>> grouped() {
    final result = <String, List<ReplacePreset>>{};
    for (final preset in all) {
      result.putIfAbsent(preset.category, () => <ReplacePreset>[]).add(preset);
    }
    return result.map(
      (category, presets) => MapEntry(category, List.unmodifiable(presets)),
    );
  }

  @override
  List<ReplaceRule> toRules(Iterable<ReplacePreset> presets) {
    return presets.map((preset) => preset.toRule()).toList();
  }

  static ReplacePreset _fromServicePreset(legacy.ReplacePreset preset) {
    return ReplacePreset(
      id: preset.id,
      category: preset.category,
      name: preset.name,
      pattern: preset.pattern,
      replacement: preset.replacement,
      isRegex: preset.isRegex,
    );
  }
}
