import '../models/replace_rule.dart';

/// 可导入的替换规则预设
class ReplacePreset {
  final String id;
  final String category;
  final String name;
  final String pattern;
  final String replacement;
  final bool isRegex;

  const ReplacePreset({
    required this.id,
    required this.category,
    required this.name,
    required this.pattern,
    this.replacement = '',
    this.isRegex = true,
  });

  ReplaceRule toRule({bool enabled = true}) => ReplaceRule(
        id: 'preset_$id',
        name: name,
        pattern: pattern,
        replacement: replacement,
        isRegex: isRegex,
        isEnabled: enabled,
      );
}

/// 预设规则库 — 常见广告/格式净化（Phase 2.2）
abstract final class ReplacePresetLibrary {
  /// 预览用样本文本
  static const sampleText = '''第一章 测试章节

正文内容开始。

笔趣阁 www.example.com 为你提供最快更新，一秒记住本站地址。

本章未完，请点击下一页继续阅读

推荐阅读：《其他书名》

\n\n\n多余空行段落。''';

  static const List<ReplacePreset> all = [
    ReplacePreset(
      id: 'ad_biquge',
      category: '广告脚注',
      name: '笔趣阁类广告脚注',
      pattern: r'笔趣阁.*?为你提供.*?更新|一秒记住.*|手机用户请浏览.*|请收藏本站.*',
    ),
    ReplacePreset(
      id: 'ad_shuwu',
      category: '广告脚注',
      name: '书屋推广语',
      pattern: r'[\s\S]*?看书就找|天才一秒记住|推荐阅读.*',
    ),
    ReplacePreset(
      id: 'ad_next_page',
      category: '页面提示',
      name: '「本章未完」提示',
      pattern: r'本章未完，请点击下一页继续阅读|最新网址.*|请记住本书发布域名.*',
    ),
    ReplacePreset(
      id: 'ad_domain',
      category: '页面提示',
      name: '域名/收藏提示',
      pattern: r'www\.[a-z0-9.-]+\.(com|net|org|cc).*?(更新|阅读|收藏)',
    ),
    ReplacePreset(
      id: 'fmt_blank_lines',
      category: '格式整理',
      name: '压缩连续空行',
      pattern: r'\n{3,}',
      replacement: '\n\n',
    ),
    ReplacePreset(
      id: 'fmt_spaces',
      category: '格式整理',
      name: '行首行尾空白',
      pattern: r'[ \t]+\n',
      replacement: '\n',
    ),
    ReplacePreset(
      id: 'sym_fullwidth_space',
      category: '特殊符号',
      name: '全角空格',
      pattern: '\u3000',
      replacement: ' ',
      isRegex: false,
    ),
    ReplacePreset(
      id: 'sym_zero_width',
      category: '特殊符号',
      name: '零宽字符',
      pattern: r'[\u200B-\u200D\uFEFF]',
    ),
  ];

  static Map<String, List<ReplacePreset>> grouped() {
    final map = <String, List<ReplacePreset>>{};
    for (final p in all) {
      map.putIfAbsent(p.category, () => []).add(p);
    }
    return map;
  }

  static List<ReplaceRule> toRules(Iterable<ReplacePreset> presets) =>
      presets.map((p) => p.toRule()).toList();
}
