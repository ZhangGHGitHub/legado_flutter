import '../models/replace_rule.dart';

/// 替换净化引擎 - 对正文应用正则替换规则
class ReplaceService {
  List<ReplaceRule> _rules = [];

  /// 加载规则
  void loadRules(List<ReplaceRule> rules) {
    _rules = rules.where((r) => r.isEnabled).toList();
  }

  /// 对文本执行所有启用的替换规则
  String apply(String text) {
    if (text.isEmpty) return text;

    var result = text;
    for (final rule in _rules) {
      try {
        if (rule.isRegex) {
          result = result.replaceAll(RegExp(rule.pattern, multiLine: true), rule.replacement);
        } else {
          result = result.replaceAll(rule.pattern, rule.replacement);
        }
      } catch (_) {
        // 规则出错时跳过
        continue;
      }
    }
    return result;
  }

  /// 内置广告过滤规则
  static List<ReplaceRule> builtInRules() {
    return [
      ReplaceRule(
        id: 'builtin_1',
        name: '去除「笔趣阁」广告脚注',
        pattern: r'笔趣阁.*?为你提供.*?更新|一秒记住.*|手机用户请浏览.*|请收藏本站.*',
        replacement: '',
      ),
      ReplaceRule(
        id: 'builtin_2',
        name: '去除「XX书屋」广告',
        pattern: r'[\s\S]*?看书就找|天才一秒记住|推荐阅读.*',
        replacement: '',
      ),
      ReplaceRule(
        id: 'builtin_3',
        name: '压缩连续空行',
        pattern: r'\n{3,}',
        replacement: '\n\n',
      ),
      ReplaceRule(
        id: 'builtin_4',
        name: '去除页面脚注版权',
        pattern: r'本章未完，请点击下一页继续阅读|最新网址.*',
        replacement: '',
      ),
    ];
  }
}
