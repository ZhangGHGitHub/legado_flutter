import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/txt_toc_rule.dart';

/// TXT 目录规则持久化 — SharedPreferences JSON，对齐 Jingshiro `txtTocRules` 表
class TxtTocRulePrefs {
  static const _kRules = 'txt_toc_rules_v1';

  static List<TxtTocRule>? _cache;

  /// 内存缓存（分章时可同步读取；UI 改动后会刷新）
  static List<TxtTocRule> get cached =>
      List.unmodifiable(_cache ?? defaultRules);

  static Future<List<TxtTocRule>> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kRules);
    if (raw == null || raw.isEmpty) {
      _cache = List<TxtTocRule>.from(defaultRules);
      await save(_cache!);
      return List<TxtTocRule>.from(_cache!);
    }
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => TxtTocRule.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      list.sort((a, b) => a.serialNumber.compareTo(b.serialNumber));
      _cache = list;
      return List<TxtTocRule>.from(list);
    } catch (_) {
      _cache = List<TxtTocRule>.from(defaultRules);
      return List<TxtTocRule>.from(_cache!);
    }
  }

  static Future<void> save(List<TxtTocRule> rules) async {
    final sorted = List<TxtTocRule>.from(rules)
      ..sort((a, b) => a.serialNumber.compareTo(b.serialNumber));
    _cache = sorted;
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _kRules,
      jsonEncode(sorted.map((e) => e.toJson()).toList()),
    );
  }

  static List<TxtTocRule> get enabledRules {
    final all = cached;
    return all
        .where((r) => r.enable && r.rule.trim().isNotEmpty)
        .toList()
      ..sort((a, b) => a.serialNumber.compareTo(b.serialNumber));
  }

  static Future<void> resetToDefaults() async {
    await save(List<TxtTocRule>.from(defaultRules));
  }

  /// 内置预设 — 对齐 Jingshiro `assets/defaultData/txtTocRule.json`
  static final List<TxtTocRule> defaultRules = [
    TxtTocRule(
      id: -1,
      enable: true,
      name: '目录(去空白)',
      rule:
          r'(?<=[　\s])(?:序章|楔子|正文(?!完|结)|终章|后记|尾声|番外|第\s{0,4}[\d〇零一二两三四五六七八九十百千万壹贰叁肆伍陆柒捌玖拾佰仟]+?\s{0,4}(?:章|节(?!课)|卷|集(?![合和]))).{0,30}$',
      example: '第一章 假装第一章前面有空白但我不要',
      serialNumber: 0,
    ),
    TxtTocRule(
      id: -2,
      enable: true,
      name: '目录',
      rule:
          r'^[ 　\t]{0,4}(?:序章|楔子|正文(?!完|结)|终章|后记|尾声|番外|第\s{0,4}[\d〇零一二两三四五六七八九十百千万壹贰叁肆伍陆柒捌玖拾佰仟]+?\s{0,4}(?:章|节(?!课)|卷|集(?![合和])|部(?![分赛游])|篇(?!张))).{0,30}$',
      example: '第一章 标准的粤语就是这样',
      serialNumber: 1,
    ),
    TxtTocRule(
      id: -3,
      enable: false,
      name: '目录(匹配简介)',
      rule:
          r'(?<=[　\s])(?:(?:内容|文章)?简介|文案|前言|序章|楔子|正文(?!完|结)|终章|后记|尾声|番外|第\s{0,4}[\d〇零一二两三四五六七八九十百千万壹贰叁肆伍陆柒捌玖拾佰仟]+?\s{0,4}(?:章|节(?!课)|卷|集(?![合和])|部(?![分赛游])|回(?![合来事去])|场(?![和合比电是])|篇(?!张))).{0,30}$',
      example: '简介 老夫诸葛村夫',
      serialNumber: 2,
    ),
    TxtTocRule(
      id: -4,
      enable: false,
      name: '目录(古典、轻小说备用)',
      rule:
          r'^[ 　\t]{0,4}(?:序章|楔子|正文(?!完|结)|终章|后记|尾声|番外|第\s{0,4}[\d〇零一二两三四五六七八九十百千万壹贰叁肆伍陆柒捌玖拾佰仟]+?\s{0,4}(?:章|节(?!课)|卷|集(?![合和])|部(?![分赛游])|回(?![合来事去])|场(?![和合比电是])|话|篇(?!张))).{0,30}$',
      example: '第一章 比上面只多了回和话',
      serialNumber: 3,
    ),
    TxtTocRule(
      id: -5,
      enable: false,
      name: '数字(纯数字标题)',
      rule: r'(?<=[　\s])\d+\.?[ 　\t]{0,4}$',
      example: '12',
      serialNumber: 4,
    ),
    TxtTocRule(
      id: -8,
      enable: true,
      name: '数字 分隔符 标题名称',
      rule: r'^[ 　\t]{0,4}\d{1,5}[:：,.， 、_—\-].{1,30}$',
      example: '1、这个就是标题',
      serialNumber: 7,
    ),
    TxtTocRule(
      id: -9,
      enable: true,
      name: '大写数字 分隔符 标题名称',
      rule:
          r'^[ 　\t]{0,4}(?:序章|楔子|正文(?!完|结)|终章|后记|尾声|番外|[零一二两三四五六七八九十百千万壹贰叁肆伍陆柒捌玖拾佰仟]{1,8}章?)[ 、_—\-].{1,30}$',
      example: '一、只有前面的数字有差别\n二十四章 我瞎编的标题',
      serialNumber: 8,
    ),
    TxtTocRule(
      id: -11,
      enable: true,
      name: '正文 标题/序号',
      rule: r'^[ 　\t]{0,4}正文[ 　]{1,4}.{0,20}$',
      example: '正文 我奶常山赵子龙',
      serialNumber: 10,
    ),
    TxtTocRule(
      id: -12,
      enable: true,
      name: 'Chapter/Section/Part/Episode 序号 标题',
      rule:
          r'^[ 　\t]{0,4}(?:[Cc]hapter|[Ss]ection|[Pp]art|ＰＡＲＴ|[Nn][oO][.、]|[Ee]pisode|(?:内容|文章)?简介|文案|前言|序章|楔子|正文(?!完|结)|终章|后记|尾声|番外)\s{0,4}\d{1,4}.{0,30}$',
      example: 'Chapter 1 MyGrandmaIsNB',
      serialNumber: 11,
    ),
    TxtTocRule(
      id: -14,
      enable: true,
      name: '特殊符号 序号 标题',
      rule:
          r'(?<=[\s　])[【〔〖「『〈［\[](?:第|[Cc]hapter)[\d零一二两三四五六七八九十百千万壹贰叁肆伍陆柒捌玖拾佰仟]{1,10}[章节].{0,20}$',
      example: '【第一章 后面的符号可以没有',
      serialNumber: 13,
    ),
    TxtTocRule(
      id: -16,
      enable: true,
      name: '特殊符号 标题(单个)',
      rule:
          r'(?<=[\s　]{0,4})(?:[☆★✦✧].{1,30}|(?:内容|文章)?简介|文案|前言|序章|楔子|正文(?!完|结)|终章|后记|尾声|番外)[ 　]{0,4}$',
      example: '☆、晋江作者最喜欢的格式',
      serialNumber: 15,
    ),
    TxtTocRule(
      id: -17,
      enable: true,
      name: '章/卷 序号 标题',
      rule:
          r'^[ \t　]{0,4}(?:(?:内容|文章)?简介|文案|前言|序章|楔子|正文(?!完|结)|终章|后记|尾声|番外|[卷章][\d零一二两三四五六七八九十百千万壹贰叁肆伍陆柒捌玖拾佰仟]{1,8})[ 　]{0,4}.{0,30}$',
      example: '卷五 开源盛世',
      serialNumber: 16,
    ),
    TxtTocRule(
      id: -21,
      enable: true,
      name: '书名 括号 序号',
      rule:
          r'^[一-龥]{1,20}[ 　\t]{0,4}[(（][\d〇零一二两三四五六七八九十百千万壹贰叁肆伍陆柒捌玖拾佰仟]{1,8}[)）][ 　\t]{0,4}$',
      example: '标题后面数字有括号(12)',
      serialNumber: 20,
    ),
    TxtTocRule(
      id: -22,
      enable: true,
      name: '书名 序号',
      rule:
          r'^[一-龥]{1,20}[ 　\t]{0,4}[\d〇零一二两三四五六七八九十百千万壹贰叁肆伍陆柒捌玖拾佰仟]{1,8}[ 　\t]{0,4}$',
      example: '标题后面数字没有括号124',
      serialNumber: 21,
    ),
    TxtTocRule(
      id: -24,
      enable: true,
      name: '字数分割 分节阅读',
      rule:
          r'(?<=[ 　\t]{0,4})(?:.{0,15}分[页节章段]阅读[-_ ]|第\s{0,4}[\d零一二两三四五六七八九十百千万]{1,6}\s{0,4}[页节]).{0,30}$',
      example: '分节|分页|分段阅读\n第一页',
      serialNumber: 23,
    ),
  ];
}
