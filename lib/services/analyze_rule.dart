part of 'rule_engine.dart';

/// Legado AnalyzeRule 执行上下文
class RuleContext {
  dynamic result;
  final String baseUrl;
  final String? bookUrl;
  final String? chapterUrl;
  final String? key;
  final BookSource? source;
  final Map<String, dynamic> cache;
  final String jsLib;

  RuleContext({
    this.result,
    this.baseUrl = '',
    this.bookUrl,
    this.chapterUrl,
    this.key,
    this.source,
    Map<String, dynamic>? cache,
    this.jsLib = '',
  }) : cache = cache ?? {};

  factory RuleContext.fromSource(
    BookSource source, {
    String baseUrl = '',
    dynamic result,
    String? key,
    String? bookUrl,
    String? chapterUrl,
  }) {
    return RuleContext(
      source: source,
      baseUrl: baseUrl.isNotEmpty ? baseUrl : source.bookSourceUrl,
      result: result,
      key: key,
      bookUrl: bookUrl,
      chapterUrl: chapterUrl,
      jsLib: source.jsLib,
    );
  }

  void putCache(String k, dynamic v) => cache[k] = v;
  dynamic getCache(String k) => cache[k];

  String resolveTemplate(String template) {
    var s = template;
    if (key != null) {
      s = s.replaceAll('{{key}}', key!).replaceAll('{{page}}', '1');
    }
    if (bookUrl != null) s = s.replaceAll('{{bookUrl}}', bookUrl!);
    if (chapterUrl != null) s = s.replaceAll('{{chapterUrl}}', chapterUrl!);
    s = _replaceCacheGetTemplate(s);
    if (result != null) {
      s = LegadoJsonPath.resolveTemplate(s, result);
    }
    return s;
  }

  String _replaceCacheGetTemplate(String s) {
    s = s.replaceAllMapped(
      RegExp(r'\{\{cache\.getFromMemory\(\s*"([^"]+)"\s*\)\}\}'),
      (m) => getCache(m.group(1)!)?.toString() ?? '',
    );
    return s.replaceAllMapped(
      RegExp(r"\{\{cache\.getFromMemory\(\s*'([^']+)'\s*\)\}\}"),
      (m) => getCache(m.group(1)!)?.toString() ?? '',
    );
  }
}

/// 统一规则解析器（Legado AnalyzeRule 子集，持续扩展）
class AnalyzeRule {
  final RuleContext ctx;
  dom.Element? htmlRoot;
  dynamic jsonRoot;

  AnalyzeRule(this.ctx, {this.htmlRoot, this.jsonRoot});

  factory AnalyzeRule.html(dom.Element root, {RuleContext? ctx}) {
    return AnalyzeRule(ctx ?? RuleContext(), htmlRoot: root);
  }

  factory AnalyzeRule.json(dynamic json, RuleContext ctx) {
    return AnalyzeRule(ctx, jsonRoot: json);
  }

  /// 提取字符串（HTML 或 JSON 自动识别）
  String getString(String rule, {dom.Element? element, dynamic jsonItem}) {
    if (rule.isEmpty) return '';
    final el = element ?? htmlRoot;
    final json = jsonItem ?? jsonRoot ?? ctx.result;

    if (rule.contains('%%')) {
      return RuleEngine._splitTopLevel(rule, '%%')
          .map((p) => getString(p.trim(), element: el, jsonItem: jsonItem))
          .where((s) => s.isNotEmpty)
          .join('\n');
    }

    if (_looksLikeJsonRule(rule) && json != null) {
      final v = getJsonString(rule, json);
      if (v.isNotEmpty) return v;
    }

    if (el != null) {
      return RuleEngine._extractByRule(el, rule, ctx: ctx);
    }
    return '';
  }

  /// 提取属性（href/src 等）
  String getAttr(String rule, String attr, {dom.Element? element}) {
    final el = element ?? htmlRoot;
    if (el == null || rule.isEmpty) return '';
    return RuleEngine._extractAttrByRule(el, rule, attr, ctx: ctx);
  }

  /// 提取 JSON 字符串
  String getJsonString(String rule, dynamic json) {
    if (rule.isEmpty || json == null) return '';
    var path = rule.trim();
    while (path.startsWith('@') && !path.startsWith('@@')) {
      path = path.substring(1).trim();
    }
    if (path.startsWith('@Json:') || path.startsWith('@json:')) {
      path = path.substring(path.indexOf(':') + 1).trim();
    }
    // 去掉 ## 后缀
    final hash = path.indexOf('##');
    if (hash >= 0) path = path.substring(0, hash);
    var value = LegadoJsonPath.resolveString(json, path);
    if (hash >= 0) {
      value = _applyRegexSuffix(rule, value);
    }
    return value;
  }

  /// 提取 JSON 列表
  List<dynamic> getJsonList(String rule, dynamic json) {
    if (rule.isEmpty || json == null) return [];
    var path = rule.trim();
    var reverse = false;
    if (path.startsWith('-')) {
      reverse = true;
      path = path.substring(1).trim();
    }
    if (path.startsWith('@Json:') || path.startsWith('@json:')) {
      path = path.substring(path.indexOf(':') + 1).trim();
    }
    final hash = path.indexOf('##');
    if (hash >= 0) path = path.substring(0, hash);

    if (path.contains('%%')) {
      final merged = <dynamic>[];
      for (final part in RuleEngine._splitTopLevel(path, '%%')) {
        merged.addAll(getJsonList(part.trim(), json));
      }
      if (reverse) return merged.reversed.toList();
      return merged;
    }

    final v = LegadoJsonPath.resolve(json, path);
    if (v == null) return [];
    if (v is List) return reverse ? v.reversed.toList() : v;
    return reverse ? [v] : [v];
  }

  /// 解析列表规则 → DOM 元素列表
  List<dom.Element> getElements(String rule, dom.Document document) {
    return RuleEngine._queryListItems(document, rule, ctx: ctx);
  }

  /// 提取正文 HTML（单页）
  String getContentHtml(String rule, dom.Document document) {
    final root = document.body;
    if (root == null || rule.isEmpty) return '';
    return RuleEngine._extractContentHtml(document, root, rule);
  }

  /// 提取链接 URL（HTML 规则 → href）
  String getLinkUrl(String rule, {dom.Element? element}) {
    final el = element ?? htmlRoot;
    if (el == null || rule.isEmpty) return '';
    if (rule.contains('||')) {
      for (final part in RuleEngine._splitTopLevel(rule, '||')) {
        final url = getLinkUrl(part.trim(), element: el);
        if (url.isNotEmpty) return url;
      }
      return '';
    }
    var url = getAttr(rule, 'href', element: el);
    if (url.isEmpty) url = getString(rule, element: el);
    return url;
  }

  /// 从 JSON 数据提取下一页 URL（JSONPath / 模板）
  String getJsonNextUrl(String rule, dynamic data) {
    if (rule.isEmpty || data == null) return '';
    if (rule.contains('<js>')) {
      final split = splitJsonJsRule(rule);
      if (split.pathPart.isNotEmpty) {
        return getJsonString(split.pathPart, data);
      }
      return '';
    }
    if (rule.contains('{{')) {
      return LegadoJsonPath.resolveTemplate(rule, data);
    }
    return getJsonString(rule, data);
  }

  /// 拆分「JSONPath\\n<js>...」组合规则
  static ({String pathPart, String jsPart}) splitJsonJsRule(String rule) {
    final jsIdx = rule.indexOf('<js>');
    if (jsIdx < 0) return (pathPart: rule.trim(), jsPart: '');
    return (
      pathPart: rule.substring(0, jsIdx).trim(),
      jsPart: rule.substring(jsIdx),
    );
  }

  /// 从组合规则提取 JSONPath 前缀值
  String extractJsonPrefix(String rule, dynamic item) {
    final split = splitJsonJsRule(rule);
    var pathPart = split.pathPart;
    if (pathPart.isEmpty) return '';
    final nl = pathPart.indexOf('\n');
    if (nl >= 0) pathPart = pathPart.substring(0, nl).trim();
    return getJsonString(pathPart, item);
  }

  /// 解析章节 URL 模板（无 JS 部分）
  String resolveChapterUrlTemplate(
    String template,
    dynamic item, {
    String articleId = '',
  }) {
    var url = template;
    if (articleId.isNotEmpty) {
      url = url.replaceAllMapped(
        RegExp(r'\{\{cache\.getFromMemory\([^)]+\)\}\}'),
        (_) => articleId,
      );
    }
    if (url.contains('{{')) {
      url = LegadoJsonPath.resolveTemplate(url, item);
    }
    return url;
  }

  static bool _looksLikeJsonRule(String rule) {
    final r = rule.trim();
    return r.startsWith(r'$') ||
        r.startsWith('@Json:') ||
        r.startsWith('@json:') ||
        r.startsWith('@JSON:');
  }

  static String _applyRegexSuffix(String rule, String value) {
    final hashIdx = rule.indexOf('##');
    if (hashIdx < 0) return value;
    final after = rule.substring(hashIdx + 2);
    final hash2 = after.indexOf('##');
    if (hash2 < 0) return value;
    try {
      return value.replaceAll(
        RegExp(after.substring(0, hash2), multiLine: true),
        after.substring(hash2 + 2),
      );
    } catch (_) {
      return value;
    }
  }
}
