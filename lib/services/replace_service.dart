import '../models/replace_rule.dart';
import 'replace_preset_library.dart';

/// 替换净化引擎 - 对正文应用正则替换规则
class ReplaceService {
  List<ReplaceRule> _rules = [];

  /// 预览默认样本文本
  static String get defaultSampleText => ReplacePresetLibrary.sampleText;

  /// 加载规则
  void loadRules(List<ReplaceRule> rules) {
    _rules = rules.where((r) => r.isEnabled).toList();
  }

  /// 对文本执行所有启用的替换规则
  String apply(String text) => applyWithRules(text, _rules);

  /// 对指定规则列表执行替换（预览/测试用）
  static String applyWithRules(String text, List<ReplaceRule> rules) {
    if (text.isEmpty) return text;

    var result = text;
    for (final rule in rules) {
      if (!rule.isEnabled) continue;
      try {
        if (rule.isRegex) {
          result = result.replaceAll(
            RegExp(rule.pattern, multiLine: true),
            rule.replacement,
          );
        } else {
          result = result.replaceAll(rule.pattern, rule.replacement);
        }
      } catch (_) {
        continue;
      }
    }
    return result;
  }

  /// 内置广告过滤规则（首次启动默认）
  static List<ReplaceRule> builtInRules() {
    return ReplacePresetLibrary.all
        .where((p) =>
            p.id == 'ad_biquge' ||
            p.id == 'ad_shuwu' ||
            p.id == 'fmt_blank_lines' ||
            p.id == 'ad_next_page')
        .map((p) => p.toRule())
        .toList();
  }
}
