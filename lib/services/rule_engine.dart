import 'dart:convert';
import 'package:html/dom.dart' as dom;
import 'package:flutter/foundation.dart';
import '../models/book_source.dart';
import 'js_evaluator.dart';

/// 全局懒加载的 JS 执行器实例
JsEvaluatorService? _jsEval;

/// 获取 JS 执行器（懒初始化）
JsEvaluatorService _getJsEval() {
  _jsEval ??= JsEvaluatorService();
  return _jsEval!;
}

/// XPath 解析器 — 支持 Legado 书源中的 XPath 选择器
///
/// 支持的语法:
///   //div                                   标签选择
///   //div[@class="hot_sale"]                属性过滤
///   //div[contains(@class, "hot")]          contains
///   //div[1]                                位置过滤
///   //a/p[1]/text()                         嵌套 + 文本提取
///   //a/@href                               属性提取
///   /html/body/div                          绝对路径
class XPathParser {
  /// 在 root 元素上执行 XPath 表达式，返回匹配的元素列表
  static List<dom.Element> queryAll(dom.Element root, String xpath) {
    if (xpath.isEmpty) return [];

    try {
      final steps = _parseSteps(xpath);
      if (steps.isEmpty) return [];

      // 检查最后一步是否为提取终端 (text(), @attr)
      final last = steps.last;
      if (last.isTerminal) {
        // 前 N-1 步定位元素
        List<dom.Element> current = [root];
        for (int i = 0; i < steps.length - 1; i++) {
          current = _applyStep(current, steps[i]);
          if (current.isEmpty) return [];
        }
        return current;
      }

      // 正常执行所有步骤
      List<dom.Element> current = [root];
      for (final step in steps) {
        current = _applyStep(current, step);
        if (current.isEmpty) return [];
      }
      return current;
    } catch (e) {
      debugPrint('  ⚠ XPath 解析失败: "$xpath" → $e');
      return [];
    }
  }

  /// 执行 XPath 并提取文本
  static String extractText(dom.Element root, String xpath) {
    final steps = _parseSteps(xpath);
    if (steps.isEmpty) return '';

    final last = steps.last;
    if (last.isTerminal && last.terminalType == 'text') {
      // text() 终端: 前 N-1 步定位
      List<dom.Element> current = [root];
      for (int i = 0; i < steps.length - 1; i++) {
        current = _applyStep(current, steps[i]);
        if (current.isEmpty) return '';
      }
      return current.map((e) => e.text.trim()).join('\n');
    }

    // 普通路径
    final elements = queryAll(root, xpath);
    return elements.isNotEmpty ? elements.first.text.trim() : '';
  }

  /// 执行 XPath 并提取属性
  static String extractAttr(dom.Element root, String xpath) {
    final steps = _parseSteps(xpath);
    if (steps.isEmpty) return '';

    final last = steps.last;
    if (last.isTerminal && last.terminalType == 'attr') {
      List<dom.Element> current = [root];
      for (int i = 0; i < steps.length - 1; i++) {
        current = _applyStep(current, steps[i]);
        if (current.isEmpty) return '';
      }
      if (current.isEmpty) return '';
      return current.first.attributes[last.attrName] ?? '';
    }

    return '';
  }

  /// �的分析 XPath 表达式为步骤列表
  static List<_XPathStep> _parseSteps(String xpath) {
    String s = xpath.trim();
    final steps = <_XPathStep>[];

    if (s.isEmpty) return steps;

    // 检测轴: 开头 // → descendant, 开头 / → child
    String firstAxis = 'child';
    if (s.startsWith('//')) {
      firstAxis = 'descendant';
      s = s.substring(2);
    } else if (s.startsWith('/')) {
      s = s.substring(1);
    }

    // 按 / 分割（但不分割 [] 内部）
    final parts = <String>[];
    int depth = 0;
    StringBuffer buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final ch = s[i];
      if (ch == '[') depth++;
      if (ch == ']') depth--;
      if (ch == '/' && depth == 0) {
        parts.add(buf.toString());
        buf = StringBuffer();
      } else {
        buf.write(ch);
      }
    }
    parts.add(buf.toString());

    for (final part in parts) {
      if (part.isEmpty) continue;
      final step = _XPathStep.parse(part);
      steps.add(step);
    }

    // 设置第一个步骤的轴（仅当不是默认 child 时）
    if (steps.isNotEmpty && firstAxis != 'child') {
      final first = steps[0];
      steps[0] = _XPathStep(
        axis: firstAxis,
        tagName: first.tagName,
        predicates: first.predicates,
      );
    }

    return steps;
  }

  /// 对元素列表应用一个 XPath 步骤
  static List<dom.Element> _applyStep(List<dom.Element> elements, _XPathStep step) {
    List<dom.Element> result = [];

    if (step.isTerminal) return elements;

    for (final el in elements) {
      List<dom.Element> candidates;

      if (step.axis == 'descendant') {
        candidates = _queryDescendants(el, step.tagName);
      } else {
        // child axis
        if (step.tagName == '*') {
          candidates = List.from(el.children);
        } else {
          candidates = el.children.where((c) =>
              c.localName?.toLowerCase() == step.tagName.toLowerCase()).toList();
        }
      }

      // 应用 predicates
      if (step.predicates.isNotEmpty) {
        // debugPrint('  ▸ XPath step: tag=$step.tagName, pred=${step.predicates.length}');
        for (final pred in step.predicates) {
          final before = candidates.length;
          candidates = _applyPredicate(candidates, pred);
          // debugPrint('  ▸ pred type=${pred.type} attr="${pred.attrName}" val="${pred.attrValue}" → $before→${candidates.length}');
          if (candidates.isEmpty) {
            // 调试：检查实际 DOM 属性值
            break;
          }
        }
      }

      result.addAll(candidates);
    }

    return result;
  }

  /// 递归查找所有后代
  static List<dom.Element> _queryDescendants(dom.Element root, String tagName) {
    final result = <dom.Element>[];
    void walk(dom.Element node) {
      for (final child in node.children) {
        if (tagName == '*' || child.localName?.toLowerCase() == tagName.toLowerCase()) {
          result.add(child);
        }
        walk(child);
      }
    }
    walk(root);
    // debugPrint('  ▸ _queryDescendants(tag=$tagName): root=${root.localName}, total=${result.length}');
    if (result.isNotEmpty) {
      for (final r in result.take(5)) {
        // debugPrint('  ▸   found: <${r.localName} id="${r.attributes['id'] ?? ''}" class="${r.attributes['class'] ?? ''}"');
      }
      // if (result.length > 5) debugPrint('  ▸   ... 还有 ${result.length - 5} 个');
    }
    return result;
  }

  /// 应用 predicate 过滤
  static List<dom.Element> _applyPredicate(List<dom.Element> elements, _XPathPredicate pred) {
    if (pred.type == 'position') {
      // position 是 1-based
      final idx = pred.position - 1;
      if (idx >= 0 && idx < elements.length) {
        return [elements[idx]];
      }
      return [];
    }

    if (pred.type == 'attr_eq') {
      return elements.where((e) =>
          (e.attributes[pred.attrName] ?? '') == pred.attrValue).toList();
    }

    if (pred.type == 'contains') {
      return elements.where((e) {
        final val = e.attributes[pred.attrName] ?? '';
        return val.contains(pred.attrValue ?? '');
      }).toList();
    }

    if (pred.type == 'has_child') {
      return elements.where((e) {
        return e.children.any((c) =>
            c.localName?.toLowerCase() == pred.tagName?.toLowerCase());
      }).toList();
    }

    return elements;
  }
}

/// XPath 的一个步骤（轴 + 节点测试 + 谓语）
class _XPathStep {
  final String axis;     // 'child' or 'descendant'
  final String tagName;  // tag name or '*'
  final bool isTerminal;
  final String? terminalType; // 'text', 'attr'
  final String? attrName;
  final List<_XPathPredicate> predicates;

  _XPathStep({
    this.axis = 'child',
    this.tagName = '*',
    this.isTerminal = false,
    this.terminalType,
    this.attrName,
    this.predicates = const [],
  });

  factory _XPathStep.parse(String raw) {
    String s = raw.trim();

    // 检测终端: text()
    if (s == 'text()') {
      return _XPathStep(isTerminal: true, terminalType: 'text');
    }

    // 检测终端: @attr
    if (s.startsWith('@')) {
      return _XPathStep(
        isTerminal: true,
        terminalType: 'attr',
        attrName: s.substring(1),
      );
    }

    String axis = 'child';
    String tagName = '*';

    // 检测 // 前缀（descendant）
    if (s.startsWith('//')) {
      axis = 'descendant';
      s = s.substring(2);
    } else if (s.startsWith('/')) {
      s = s.substring(1);
    }

    // 提取 tag 名（在第一个 [ 之前）
    final bracketIdx = s.indexOf('[');
    String tagPart;
    String rest = '';
    if (bracketIdx >= 0) {
      tagPart = s.substring(0, bracketIdx);
      rest = s.substring(bracketIdx);
    } else {
      tagPart = s;
    }

    if (tagPart.isNotEmpty && tagPart != '*') {
      tagName = tagPart;
    }

    // 解析 predicates
    final predicates = <_XPathPredicate>[];
    if (rest.isNotEmpty) {
      // 提取所有 [...]
      int i = 0;
      while (i < rest.length) {
        if (rest[i] == '[') {
          final end = _findBracketEnd(rest, i);
          if (end > i) {
            final inner = rest.substring(i + 1, end);
            predicates.add(_XPathPredicate.parse(inner.trim()));
            i = end + 1;
          } else {
            i++;
          }
        } else {
          i++;
        }
      }
    }

    return _XPathStep(
      axis: axis,
      tagName: tagName,
      predicates: predicates,
    );
  }

  static int _findBracketEnd(String s, int start) {
    int depth = 1;
    for (int i = start + 1; i < s.length; i++) {
      if (s[i] == '[') depth++;
      if (s[i] == ']') {
        depth--;
        if (depth == 0) return i;
      }
    }
    return -1;
  }
}

/// XPath predicate （[条件]）
class _XPathPredicate {
  final String type;    // 'position', 'attr_eq', 'contains', 'has_child'
  final int position;
  final String? attrName;
  final String? attrValue;
  final String? tagName;

  _XPathPredicate({
    this.type = 'position',
    this.position = 1,
    this.attrName,
    this.attrValue,
    this.tagName,
  });

  factory _XPathPredicate.parse(String raw) {
    String s = raw.trim();

    // 纯数字 → position
    final num = int.tryParse(s);
    if (num != null) {
      return _XPathPredicate(type: 'position', position: num);
    }

    // position()=n
    final posMatch = RegExp(r'position\s*\(\s*\)\s*=\s*(\d+)').firstMatch(s);
    if (posMatch != null) {
      return _XPathPredicate(
        type: 'position',
        position: int.tryParse(posMatch.group(1) ?? '1') ?? 1,
      );
    }

    // @attr="value"
    final attrEqMatch = RegExp(r"""@([\w-]+)\s*=\s*"([^"]*)"|@([\w-]+)\s*=\s*'([^']*)'""").firstMatch(s);
    if (attrEqMatch != null) {
      return _XPathPredicate(
        type: 'attr_eq',
        attrName: attrEqMatch.group(1) ?? attrEqMatch.group(3) ?? '',
        attrValue: attrEqMatch.group(2) ?? attrEqMatch.group(4) ?? '',
      );
    }

    // contains(@attr, "value")
    final containsMatch = RegExp(r"""contains\s*\(\s*@([\w-]+)\s*,\s*"([^"]*)"\s*\)""").firstMatch(s);
    if (containsMatch != null) {
      return _XPathPredicate(
        type: 'contains',
        attrName: containsMatch.group(1) ?? '',
        attrValue: containsMatch.group(2) ?? '',
      );
    }

    // 子元素存在测试: p, div, etc.
    if (RegExp(r'^[\w-]+$').hasMatch(s)) {
      return _XPathPredicate(type: 'has_child', tagName: s);
    }

    return _XPathPredicate();
  }
}
class JsonPath {
  /// 按路径取值，支持 $.data.items[0].name 或 $.data.items
  static dynamic resolve(dynamic root, String path) {
    if (root == null || path.isEmpty) return null;
    String p = path;
    // 去掉开头的 $.
    if (p.startsWith('\$.')) p = p.substring(2);
    if (p.startsWith('.')) p = p.substring(1);

    dynamic current = root;
    // 按 . 或 [] 分割
    final parts = p.split(RegExp(r'\.|(?=\[)'));
    for (final part in parts) {
      if (current == null) return null;
      final clean = part.replaceAll('[', '').replaceAll(']', '').replaceAll("'", '').replaceAll('"', '');
      if (clean.isEmpty) continue;

      // 尝试按索引取值
      int? idx;
      if (part.contains('[') && part.contains(']')) {
        // 从 [] 中提取数字索引
        final match = RegExp(r'\[(\d+)\]').firstMatch(part);
        if (match != null) {
          idx = int.tryParse(match.group(1)!);
        }
      }

      if (current is Map) {
        current = current[clean];
      } else if (current is List) {
        if (idx != null && idx < current.length) {
          current = current[idx];
        } else {
          // 遍历列表返回所有匹配值的列表
          return current.map((e) => e is Map ? e[clean] : null).toList();
        }
      } else {
        return null;
      }
    }
    return current;
  }

  /// 从路径取字符串值
  static String resolveString(dynamic root, String path) {
    final v = resolve(root, path);
    if (v == null) return '';
    if (v is List) return v.join(', ');
    return v.toString();
  }

  /// 替换模板中的 {{$.xxx}} 占位符
  static String resolveTemplate(String template, dynamic data) {
    return template.replaceAllMapped(
      RegExp(r'\{\{(.+?)\}\}'),
      (m) => resolveString(data, m.group(1)!.trim()),
    );
  }
}

/// CSS 选择器工具类
class CssSelector {
  /// 提取元素文本列表
  static List<String> extractText(dom.Element root, String selector) {
    try {
      return root.querySelectorAll(selector).map((e) => e.text.trim()).toList();
    } catch (_) {
      return [];
    }
  }

  /// 提取元素 href 属性
  static List<String> extractHref(dom.Element root, String selector) {
    try {
      return root
          .querySelectorAll(selector)
          .map((e) => e.attributes['href'] ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 提取元素单个文本
  static String extractOneText(dom.Element root, String selector) {
    try {
      return root.querySelector(selector)?.text.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  /// 提取元素单个属性
  static String extractOneAttr(dom.Element root, String selector, String attr) {
    try {
      return root.querySelector(selector)?.attributes[attr] ?? '';
    } catch (_) {
      return '';
    }
  }

  /// 提取内部 HTML
  static String extractInnerHtml(dom.Element root, String selector) {
    try {
      final el = root.querySelector(selector);
      return el?.innerHtml ?? '';
    } catch (_) {
      return '';
    }
  }

  /// 使用正则表达式提取
  static List<String> extractRegex(String text, String pattern) {
    try {
      final regex = RegExp(pattern, multiLine: true);
      return regex.allMatches(text).map((m) => m.group(1) ?? m.group(0) ?? '').toList();
    } catch (_) {
      return [];
    }
  }
}

/// Legado 默认规则解析器
///
/// 支持 Legado 专有选择器语法:
///   class.odd.0@tag.a@text          — 嵌套选择
///   tag.dd.0@tag.h1@text##替换##    — 带正则替换
///   tag.td!0@text                   — 排除第0个
///   -tag.td@text                    — 反序
///   tag.td[1:3]@text                — 数组切片
///   tag.td||tag.div@text            — 多规则 OR
///   tag.td&&tag.div@text            — 多规则 AND
///   @css:div.title a@text           — CSS 选择器
///   tag.a@href                      — 提取 href
class LegadoRule {
  final String raw;
  final List<LegadoSegment> segments;
  final String? regexPattern;
  final String? regexReplacement;

  LegadoRule({
    required this.raw,
    required this.segments,
    this.regexPattern,
    this.regexReplacement,
  });

  /// 解析 Legado 规则字符串
  factory LegadoRule.parse(String rule) {
    String r = rule.trim();
    
    // 1) 提取 ##regex##replacement
    String? regexPattern;
    String? regexReplacement;
    final hashIdx = r.indexOf('##');
    if (hashIdx >= 0) {
      final afterHash = r.substring(hashIdx + 2);
      final hash2Idx = afterHash.indexOf('##');
      if (hash2Idx >= 0) {
        regexPattern = afterHash.substring(0, hash2Idx);
        regexReplacement = afterHash.substring(hash2Idx + 2);
        r = r.substring(0, hashIdx);
      }
    }

    // 2) 按 @ 分割为选择段（避开 [] 内部的 @）
    final rawSegments = _splitByAt(r);
    final segments = rawSegments.map((s) => LegadoSegment.parse(s.trim())).toList();

    return LegadoRule(
      raw: rule,
      segments: segments,
      regexPattern: regexPattern,
      regexReplacement: regexReplacement,
    );
  }

  /// 按 @ 分割，但避开 [] 内部的 @（用于 XPath）
  static List<String> _splitByAt(String s) {
    final parts = <String>[];
    int depth = 0;
    StringBuffer buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final ch = s[i];
      if (ch == '[') depth++;
      if (ch == ']') depth--;
      if (ch == '@' && depth == 0) {
        parts.add(buf.toString());
        buf = StringBuffer();
      } else {
        buf.write(ch);
      }
    }
    parts.add(buf.toString());
    return parts;
  }

  /// 在文档/元素上执行规则，返回匹配的元素列表
  List<dom.Element> queryAll(dom.Element root) {
    if (segments.isEmpty) return [root];

    List<dom.Element> current = [root];

    // 除了最后一段，其他都是过滤/选择段
    // 最后一段可能是提取终端（@text, @href, @src 等）
    for (int i = 0; i < segments.length; i++) {
      current = segments[i].applyAll(current);
      if (current.isEmpty) return [];
    }

    return current;
  }

  /// 执行规则并提取文本值
  String extractText(dom.Element root) {
    // 最后一段如果是终端（text/href/src/html等），前面的段用来定位
    if (segments.isEmpty) return '';

    final last = segments.last;
    if (last.isTerminal) {
      // 前 N-1 段定位元素
      List<dom.Element> parents = [root];
      for (int i = 0; i < segments.length - 1; i++) {
        parents = segments[i].applyAll(parents);
        if (parents.isEmpty) return '';
      }
      return last.extractFromElements(parents);
    } else {
      // 所有段定位元素，然后取文本
      final elements = queryAll(root);
      return elements.isNotEmpty ? elements.first.text.trim() : '';
    }
  }

  /// 执行规则并提取多个值
  List<String> extractAllText(dom.Element root) {
    if (segments.isEmpty) return [];

    final last = segments.last;
    if (last.isTerminal) {
      List<dom.Element> parents = [root];
      for (int i = 0; i < segments.length - 1; i++) {
        parents = segments[i].applyAll(parents);
        if (parents.isEmpty) return [];
      }
      return last.extractAllFromElements(parents);
    } else {
      final elements = queryAll(root);
      return elements.map((e) => e.text.trim()).toList();
    }
  }

  /// 执行规则并提取属性值（href/src 等）
  String extractAttr(dom.Element root, String attr) {
    if (segments.isEmpty) return '';
    final last = segments.last;
    if (last.isTerminal) {
      // 前 N-1 段定位元素，再取属性
      List<dom.Element> parents = [root];
      for (int i = 0; i < segments.length - 1; i++) {
        parents = segments[i].applyAll(parents);
        if (parents.isEmpty) return '';
      }
      return parents.isNotEmpty ? parents.first.attributes[attr] ?? '' : '';
    }
    final elements = queryAll(root);
    if (elements.isEmpty) return '';
    return elements.first.attributes[attr] ?? '';
  }

  /// 应用正则替换
  String applyRegex(String text) {
    if (regexPattern == null) return text;
    try {
      return text.replaceAll(RegExp(regexPattern!), regexReplacement ?? '');
    } catch (_) {
      return text;
    }
  }
}

/// Legado 规则的一个选择段
class LegadoSegment {
  final String raw;
  final String type;    // class, id, tag, text, children, css, css:
  final String name;
  final List<int> positions;  // 空=全部
  final bool reversed;
  final bool isTerminal;  // text, href, src, html, ownText, textNodes
  final String? terminalType; // text, href, src, html, ownText, textNodes, all
  final List<int> excluded;

  LegadoSegment({
    required this.raw,
    required this.type,
    required this.name,
    this.positions = const [],
    this.reversed = false,
    this.isTerminal = false,
    this.terminalType,
    this.excluded = const [],
  });

  /// 解析一段选择器
  /// 格式: [type].[name][position/exclusion]
  /// 示例: class.odd.0, tag.a, text, href, -tag.dd, tag.td!0
  factory LegadoSegment.parse(String raw) {
    String s = raw.trim();
    bool reversed = false;
    if (s.startsWith('-')) {
      reversed = true;
      s = s.substring(1);
    }

    // 检查是否为终端类型
    final terminalTypes = ['text', 'href', 'src', 'html', 'ownText', 'textNodes', 'all'];
    if (terminalTypes.contains(s)) {
      return LegadoSegment(
        raw: raw,
        type: s,
        name: '',
        isTerminal: true,
        terminalType: s,
        reversed: reversed,
      );
    }

    // 检查 CSS 选择器 @css:
    if (s.startsWith('css:') || s.startsWith('css ')) {
      final cssSelector = s.contains(':') ? s.substring(4).trim() : s.substring(3).trim();
      return LegadoSegment(
        raw: raw,
        type: 'css',
        name: cssSelector,
        reversed: reversed,
      );
    }

    // 检查显式 @xpath: 前缀
    if (s.startsWith('xpath:') || s.startsWith('xpath ')) {
      final xpathExpr = s.contains(':') ? s.substring(6).trim() : s.substring(5).trim();
      return LegadoSegment(
        raw: raw,
        type: 'xpath',
        name: xpathExpr,
        reversed: reversed,
      );
    }

    // 检查 @js: 前缀（Legado 的 JS 表达式）
    if (s.startsWith('js:') || s.startsWith('js ')) {
      final jsExpr = s.contains(':') ? s.substring(3).trim() : s.substring(2).trim();
      return LegadoSegment(
        raw: raw,
        type: 'js',
        name: jsExpr,
        isTerminal: true,
        terminalType: 'js',
        reversed: reversed,
      );
    }

    // 检查 XPath (以 // 或 / 开头，但不是 @ 属性)
    if (s.startsWith('//') || (s.startsWith('/') && !s.startsWith('//'))) {
      return LegadoSegment(
        raw: raw,
        type: 'xpath',
        name: s,
        reversed: reversed,
      );
    }

    // 解析 type.name[positions]
    // 按 . 分割，最多3段: type, name, position
    final parts = s.split('.');
    String type;
    String name;
    List<int> positions = [];
    List<int> excluded = [];

    if (parts.length == 1) {
      // 只有 name → 默认 tag 类型
      type = 'tag';
      name = parts[0];
    } else if (parts[0].isEmpty) {
      // 以 . 开头 → class 类型（如 ".itemtxt h3 a"）
      type = 'class';
      name = parts.sublist(1).join('.');
    } else {
      type = parts[0].toLowerCase();
      name = parts[1];
      // 第三段: 位置/排除/数组
      if (parts.length >= 3) {
        final posStr = parts.sublist(2).join('.');
        _parsePositions(posStr, positions, excluded);
      }
    }

    return LegadoSegment(
      raw: raw,
      type: type,
      name: name,
      positions: positions,
      excluded: excluded,
      reversed: reversed,
    );
  }

  static void _parsePositions(String posStr, List<int> positions, List<int> excluded) {
    // 处理排除: !0, !0:2
    if (posStr.startsWith('!')) {
      final rest = posStr.substring(1);
      if (rest.contains(':')) {
        final range = rest.split(':');
        final start = int.tryParse(range[0]) ?? 0;
        final end = range.length > 1 ? int.tryParse(range[1]) ?? 0 : start;
        for (int i = start; i < end; i++) {
          excluded.add(i);
        }
      } else {
        final parts = rest.split(',');
        for (final p in parts) {
          final n = int.tryParse(p.trim());
          if (n != null) excluded.add(n);
        }
      }
      return;
    }

    // 处理数组切片: [1], [:5], [1:3], [::2]
    if (posStr.startsWith('[') && posStr.endsWith(']')) {
      final inner = posStr.substring(1, posStr.length - 1);
      final parts = inner.split(':');
      if (parts.length == 1) {
        // [1] → 单个索引
        final n = int.tryParse(parts[0]);
        if (n != null) positions.add(n);
      } else {
        // 切片 [start:end:step]
        // 暂时简化: 只处理单段
      }
      return;
    }

    // 单独的数字
    final n = int.tryParse(posStr);
    if (n != null) {
      positions.add(n);
    }
  }

  /// 对元素列表应用此段选择，返回匹配的子元素列表
  List<dom.Element> applyAll(List<dom.Element> elements) {
    List<dom.Element> result = [];

    for (final el in elements) {
      switch (type) {
        case 'tag':
          result.addAll(el.querySelectorAll(name));
          break;
        case 'class':
          result.addAll(el.querySelectorAll('.$name'));
          break;
        case 'id':
          final found = el.querySelector('#$name');
          if (found != null) result.add(found);
          break;
        case 'children':
          result.addAll(el.children.where((c) =>
              name.isEmpty || c.localName == name));
          break;
        case 'xpath':
          try {
            result.addAll(XPathParser.queryAll(el, name));
          } catch (_) {
            debugPrint('  ⚠ XPath 执行失败: "$name"');
          }
          break;
        case 'css':
          try {
            result.addAll(el.querySelectorAll(name));
          } catch (_) {}
          break;
        case 'js':
          // @js: 是终端类型，选择器层面不做处理，透传元素
          result.add(el);
          break;
        default:
          if (type.isNotEmpty) {
            try {
              result.addAll(el.querySelectorAll(type));
            } catch (_) {}
          }
      }
    }

    // 排除
    if (excluded.isNotEmpty) {
      result = result.where((e) => !excluded.contains(result.indexOf(e))).toList();
    }

    // 位置过滤
    if (positions.isNotEmpty) {
      result = positions
          .where((i) => i >= 0 && i < result.length)
          .map((i) => result[i])
          .toList();
    }

    // 反序
    if (reversed) {
      result = result.reversed.toList();
    }

    return result;
  }

  /// 从元素列表提取单个值（终端类型）
  String extractFromElements(List<dom.Element> elements) {
    if (elements.isEmpty) return '';
    return _extractSingle(elements.first);
  }

  /// 从元素列表提取多个值（终端类型）
  List<String> extractAllFromElements(List<dom.Element> elements) {
    return elements.map((e) => _extractSingle(e)).toList();
  }

  String _extractSingle(dom.Element el) {
    switch (terminalType) {
      case 'text':
        return el.text.trim();
      case 'href':
        return el.attributes['href'] ?? '';
      case 'src':
        return el.attributes['src'] ?? '';
      case 'html':
        return el.innerHtml.trim();
      case 'ownText':
        // 只取直接文本，不包含子元素
        return el.nodes
            .where((n) => n.nodeType == dom.Node.TEXT_NODE)
            .map((n) => n.text?.trim() ?? '')
            .join('')
            .trim();
      case 'textNodes':
        return el.nodes
            .where((n) => n.nodeType == dom.Node.TEXT_NODE)
            .map((n) => n.text?.trim() ?? '')
            .where((t) => t.isNotEmpty)
            .join('\n');
      case 'all':
        return el.outerHtml.trim();
      case 'js':
        // 执行 @js: 表达式，以元素文本/属性为上下文
        final String expr = name;
        // 构建包含元素信息的 data
        final data = <String, dynamic>{
          'result': el.text.trim(),
          'text': el.text.trim(),
          'html': el.innerHtml.trim(),
          'href': el.attributes['href'] ?? '',
          'src': el.attributes['src'] ?? '',
          'outerHtml': el.outerHtml.trim(),
        };
        // 添加所有属性
        for (final entry in el.attributes.entries) {
          data[entry.key as String] = entry.value;
        }
        final engine = _getJsEval();
        return engine.eval(expr, data);
      default:
        return el.text.trim();
    }
  }
}

/// 书源规则引擎 - 根据书源配置解析网页
class RuleEngine {
  /// 判断是否为 Legado 默认规则（非纯 CSS）
  static bool _isLegadoRule(String rule) {
    if (rule.isEmpty) return false;
    // 连接符
    if (rule.contains('||') || rule.contains('&&') || rule.contains('%%')) return true;
    // Legado 特征: 包含 @ 分隔符
    if (rule.contains('@')) return true;
    // 以 class./tag./id./children 开头
    if (RegExp(r'^(class|tag|id|children)\.').hasMatch(rule)) return true;
    // 以 - 开头（反序）
    if (rule.startsWith('-')) return true;
    // XPath 选择器（以 // 或 / 开头）
    if (rule.startsWith('//') || rule.startsWith('/')) return true;
    // 终端类型
    if (['text', 'href', 'src', 'html', 'ownText', 'textNodes', 'all'].contains(rule)) return true;
    return false;
  }

  /// 统一提取 - 自动识别 CSS / Legado 规则，支持 || 和 && 连接符
  static String _extractByRule(dom.Element root, String rule) {
    if (rule.isEmpty) return '';

    // ── || 连接符: 多个规则依次尝试，返回第一个非空 ──
    if (rule.contains('||')) {
      final parts = _splitTopLevel(rule, '||');
      for (final part in parts) {
        final result = _extractByRule(root, part.trim());
        if (result.isNotEmpty) return result;
      }
      return '';
    }

    // ── && 连接符: 多个规则的结果拼接 ──
    if (rule.contains('&&')) {
      final parts = _splitTopLevel(rule, '&&');
      return parts.map((part) => _extractByRule(root, part.trim())).join('');
    }

    if (_isLegadoRule(rule)) {
      try {
        final parsed = LegadoRule.parse(rule);
        String result = parsed.extractText(root);
        return parsed.applyRegex(result);
      } catch (e) {
        debugPrint('  ⚠ Legado规则解析失败: $e');
        return '';
      }
    }
    return CssSelector.extractOneText(root, rule);
  }

  static String _extractAttrByRule(dom.Element root, String rule, String attr) {
    if (rule.isEmpty) return '';

    // ── || 连接符 ──
    if (rule.contains('||')) {
      final parts = _splitTopLevel(rule, '||');
      for (final part in parts) {
        final result = _extractAttrByRule(root, part.trim(), attr);
        if (result.isNotEmpty) return result;
      }
      return '';
    }

    // ── && 连接符 ──
    if (rule.contains('&&')) {
      final parts = _splitTopLevel(rule, '&&');
      return parts.map((part) => _extractAttrByRule(root, part.trim(), attr)).join('');
    }

    if (_isLegadoRule(rule)) {
      try {
        final parsed = LegadoRule.parse(rule);
        String result = parsed.extractAttr(root, attr);
        return parsed.applyRegex(result);
      } catch (e) {
        debugPrint('  ⚠ Legado规则解析失败: $e');
        return '';
      }
    }
    return CssSelector.extractOneAttr(root, rule, attr);
  }

  /// 在顶层分割连接符（避开 ##...## 内部）
  static List<String> _splitTopLevel(String s, String separator) {
    final parts = <String>[];
    int depth = 0;
    bool inRegex = false;
    StringBuffer buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (s[i] == '#' && i + 1 < s.length && s[i + 1] == '#') {
        inRegex = !inRegex;
        buf.write('##');
        i++;
        continue;
      }
      if (!inRegex && s.startsWith(separator, i)) {
        parts.add(buf.toString());
        buf = StringBuffer();
        i += separator.length - 1;
      } else {
        buf.write(s[i]);
      }
    }
    parts.add(buf.toString());
    return parts;
  }

  /// 从搜索结果页提取书籍列表
  static List<Map<String, String>> parseSearchResults(
    dom.Document document, {
    required BookSource source,
  }) {
    final results = <Map<String, String>>[];
    final hasCustomRules = source.ruleSearchList.isNotEmpty;

    List<dom.Element> items;
    if (hasCustomRules) {
      try {
        if (_isLegadoRule(source.ruleSearchList)) {
          // Legado 规则搜索列表
          final parsed = LegadoRule.parse(source.ruleSearchList);
          items = parsed.queryAll(document.body!);
        } else {
          items = document.querySelectorAll(source.ruleSearchList);
        }
      } catch (e) {
        debugPrint('  ⚠ 搜索列表规则无效 ("${source.ruleSearchList}"): $e');
        items = _smartFindSearchItems(document);
      }
    } else {
      items = _smartFindSearchItems(document);
    }

    for (final item in items) {
      String name = '';
      String author = '';
      String url = '';
      String coverUrl = '';
      String kind = '';
      String note = '';

      if (hasCustomRules) {
        name = _extractByRule(item, source.ruleSearchName);
        author = _extractByRule(item, source.ruleSearchAuthor);
        // URL 提取: 优先用 ruleSearch.bookUrl，回退从 ruleSearchName 提取 href
        final urlRule = source.ruleSearchBookUrl.isNotEmpty
            ? source.ruleSearchBookUrl
            : source.ruleSearchName;
        if (_isLegadoRule(urlRule)) {
          final parsed = LegadoRule.parse(urlRule);
          url = parsed.extractAttr(item, 'href');
          if (url.isEmpty) url = parsed.extractText(item);
        } else {
          url = CssSelector.extractOneAttr(item, urlRule, 'href');
        }
        if (url.isEmpty) url = CssSelector.extractOneAttr(item, 'a', 'href');
        if (source.ruleSearchCoverUrl.isNotEmpty) {
          coverUrl = _extractByRule(item, source.ruleSearchCoverUrl);
          if (coverUrl.isEmpty && _isLegadoRule(source.ruleSearchCoverUrl)) {
            // Legado 规则提取 src
          } else if (coverUrl.isEmpty) {
            coverUrl = CssSelector.extractOneAttr(item, source.ruleSearchCoverUrl, 'src');
          }
        }
        // 兜底：自动查找第一张图片
        if (coverUrl.isEmpty) {
          final img = item.querySelector('img');
          if (img != null) {
            coverUrl = img.attributes['src'] ?? img.attributes['data-src'] ?? '';
          }
        }
      } else {
        // 智能识别：找链接 + 文本
        final link = item.querySelector('a');
        if (link != null) {
          name = link.text.trim();
          url = link.attributes['href'] ?? '';
        }
        if (name.isEmpty) name = item.text.trim();
        if (url.isEmpty) url = item.attributes['href'] ?? '';
        // 智能识别封面：从搜索结果项中找第一张图片
        final img = item.querySelector('img');
        if (img != null) {
          coverUrl = img.attributes['src'] ?? img.attributes['data-src'] ?? '';
        }
      }

      if (name.isNotEmpty && url.isNotEmpty) {
        results.add({
          'name': name,
          'author': author,
          'url': url,
          'coverUrl': coverUrl,
          'kind': kind,
          'note': note,
        });
      }
    }
    // debugPrint('  ▸ parseSearchResults 返回 ${results.length} 条结果');
    return results;
  }

  /// 从书籍详情页提取信息
  static Map<String, String> parseBookDetail(
    dom.Document document, {
    required BookSource source,
  }) {
    final info = <String, String>{};
    if (source.ruleBookName.isNotEmpty) {
      info['name'] = CssSelector.extractOneText(document.body!, source.ruleBookName);
    }
    if (source.ruleBookAuthor.isNotEmpty) {
      info['author'] = CssSelector.extractOneText(document.body!, source.ruleBookAuthor);
    }
    if (source.ruleBookCoverUrl.isNotEmpty) {
      info['coverUrl'] = CssSelector.extractOneAttr(document.body!, source.ruleBookCoverUrl, 'src');
    }
    if (source.ruleBookKind.isNotEmpty) {
      info['kind'] = CssSelector.extractOneText(document.body!, source.ruleBookKind);
    }
    if (source.ruleBookNote.isNotEmpty) {
      info['note'] = CssSelector.extractInnerHtml(document.body!, source.ruleBookNote);
    }
    if (source.ruleBookLastChapter.isNotEmpty) {
      info['lastChapter'] = CssSelector.extractOneText(document.body!, source.ruleBookLastChapter);
    }
    return info;
  }

  /// 提取目录列表
  static List<Map<String, String>> parseChapters(
    dom.Document document, {
    required BookSource source,
  }) {
    final chapters = <Map<String, String>>[];
    final hasCustomRules = source.ruleChapterList.isNotEmpty;

    List<dom.Element> items;
    if (hasCustomRules) {
      try {
        if (_isLegadoRule(source.ruleChapterList)) {
          final parsed = LegadoRule.parse(source.ruleChapterList);
          items = parsed.queryAll(document.body!);
        } else {
          items = document.querySelectorAll(source.ruleChapterList);
        }
      } catch (e) {
        debugPrint('  ⚠ 目录列表规则无效 ("${source.ruleChapterList}"): $e');
        items = _smartFindChapterItems(document);
      }
    } else {
      items = _smartFindChapterItems(document);
    }

    for (final item in items) {
      String title = '';
      String url = '';

      if (hasCustomRules) {
        title = _extractByRule(item, source.ruleChapterName);
        if (_isLegadoRule(source.ruleChapterUrl)) {
          final parsed = LegadoRule.parse(source.ruleChapterUrl);
          url = parsed.extractAttr(item, 'href');
        } else {
          url = CssSelector.extractOneAttr(item, source.ruleChapterUrl, 'href');
        }
        if (url.isEmpty) url = CssSelector.extractOneAttr(item, 'a', 'href');
      } else {
        final link = item.querySelector('a');
        if (link != null) {
          title = link.text.trim();
          url = link.attributes['href'] ?? '';
        }
        if (title.isEmpty) title = item.text.trim();
        if (url.isEmpty) url = item.attributes['href'] ?? '';
      }

      if (title.isNotEmpty && url.isNotEmpty) {
        chapters.add({'title': title, 'url': url});
      }
    }
    return chapters;
  }

  /// 提取正文
  static String parseContent(
    dom.Document document, {
    required BookSource source,
  }) {
    String content;

    if (source.ruleContent.isNotEmpty) {
      // 兜底: 如果 ruleContent 是 {content: ...} 格式（脏数据），提取 content 值
      String effectiveRule = source.ruleContent;
      if (effectiveRule.trimLeft().startsWith('{') && effectiveRule.contains(':')) {
        try {
          // 尝试解析为 Legado 嵌套格式: {content: "XPath", replaceRegex: "##...##"}
          // 用冒号分割取 content 后的值
          // 宽松提取: content: <值>（值可能含引号如 //div[@id="chaptercontent"]）
          final contentStart = effectiveRule.indexOf('content:');
          final replaceStart = effectiveRule.indexOf(', replaceRegex:', contentStart + 8);
          if (contentStart >= 0 && replaceStart > contentStart) {
            var extracted = effectiveRule.substring(contentStart + 8, replaceStart).trim();
            // 去掉可能包裹的引号
            extracted = extracted.replaceAll(RegExp(r'''^['"]|['"]$'''), '');
            effectiveRule = extracted;
          }
        } catch (_) {}
      }

      if (_isLegadoRule(effectiveRule)) {
        content = _extractByRule(document.body!, effectiveRule);
      } else {
        content = CssSelector.extractInnerHtml(document.body!, source.ruleContent);
      }
    } else {
      content = _smartExtractContent(document);
    }

    // 去除不需要的元素
    if (source.ruleContentRemove.isNotEmpty && content.isNotEmpty) {
      try {
        final doc = dom.DocumentFragment.html(content);
        for (final sel in source.ruleContentRemove.split(',')) {
          for (final el in doc.querySelectorAll(sel.trim())) {
            el.remove();
          }
        }
        content = doc.nodes.map((n) => n.text).join('\n');
      } catch (_) {}
    }

    // 清理 HTML 标签
    content = content
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&lt;'), '<')
        .replaceAll(RegExp(r'&gt;'), '>')
        .replaceAll(RegExp(r'&amp;'), '&')
        .trim();

    // 压缩连续空行
    content = content.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // 去掉 script 残留文本（如 js 函数调用 txt_center()）
    content = content.replaceAll(RegExp(r'^\s*txt_center\s*\(\s*\)\s*'), '');

    return content;
  }

  /// 从 JSON API 搜索结果中提取书籍列表
  /// 适用于 Legado 书源的 ruleSearch 对象（JSONPath 语法）
  static List<Map<String, String>> parseJsonSearchResults(
    String jsonStr, {
    required BookSource source,
  }) {
    final results = <Map<String, String>>[];
    if (source.rawSourceJson.isEmpty) {
      return results;
    }

    try {
      final ruleSearch = jsonDecode(source.ruleSearchJson) as Map<String, dynamic>;

      final root = jsonDecode(jsonStr);

      // 1. 获取书籍列表路径
      final bookListPath = ruleSearch['bookList'] as String? ?? '';
      if (bookListPath.isEmpty) return results;

      dynamic items = JsonPath.resolve(root, bookListPath);
      if (items == null) return results;
      if (items is! List) items = [items];

      // 2. 获取字段路径
      final namePath = ruleSearch['name'] as String? ?? '';
      final authorPath = ruleSearch['author'] as String? ?? '';
      final bookUrlPath = ruleSearch['bookUrl'] as String? ?? '';
      final coverUrlPath = ruleSearch['coverUrl'] as String? ?? '';
      final introPath = ruleSearch['intro'] as String? ?? '';

      for (final item in items) {
        final name = namePath.isNotEmpty ? JsonPath.resolveString(item, namePath) : '';
        if (name.isEmpty) continue;

        String url = '';
        if (bookUrlPath.isNotEmpty) {
          // 可能是模板（含 {{}}）或直接路径
          if (bookUrlPath.contains('{{')) {
            url = JsonPath.resolveTemplate(bookUrlPath, item);
          } else {
            url = JsonPath.resolveString(item, bookUrlPath);
          }
        }

        results.add({
          'name': name,
          'author': authorPath.isNotEmpty ? JsonPath.resolveString(item, authorPath) : '',
          'url': url,
          'coverUrl': coverUrlPath.isNotEmpty ? JsonPath.resolveString(item, coverUrlPath) : '',
          'kind': '',
          'note': introPath.isNotEmpty ? JsonPath.resolveString(item, introPath) : '',
        });
      }
    } catch (e) {
      debugPrint('  parseJsonSearchResults 解析错误: $e');
    }
    return results;
  }

  /// URL 补全
  static String resolveUrl(String url, String baseUrl) {
    if (url.startsWith('http')) return url;
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    if (url.startsWith('/')) return '$base$url';
    return '$base/$url';
  }

  // ── 智能识别（无规则兜底） ──

  static List<dom.Element> _smartFindSearchItems(dom.Document document) {
    final body = document.body!;
    // 尝试常见容器
    for (final sel in ['.result-item', '.search-item', '.list-item', 'li', '.book-list a']) {
      try {
        final items = body.querySelectorAll(sel);
        if (items.length >= 3) return items;
      } catch (_) {}
    }
    // 最后兜底：所有 a 链接
    return body.querySelectorAll('a').where((a) {
      final href = a.attributes['href'] ?? '';
      return a.text.length > 2 && href.isNotEmpty && !href.startsWith('#');
    }).toList();
  }

  static List<dom.Element> _smartFindChapterItems(dom.Document document) {
    final body = document.body!;
    // 智能容器识别
    for (final sel in ['#list a', '.chapter-list a', '.chapters a', 'ul a', '.list a']) {
      try {
        final items = body.querySelectorAll(sel);
        if (items.length >= 3) return items;
      } catch (_) {}
    }
    // 尝试找包含"章"的链接
    final allLinks = body.querySelectorAll('a').where((a) {
      return a.text.contains('章') || a.text.contains('节') || a.text.contains('Chapter');
    }).toList();
    if (allLinks.length >= 3) return allLinks;

    // 兜底：所有链接
    return body.querySelectorAll('a').where((a) {
      final href = a.attributes['href'] ?? '';
      return a.text.length > 1 && href.isNotEmpty;
    }).toList();
  }

  static String _smartExtractContent(dom.Document document) {
    final body = document.body!;
    // 尝试常见正文容器
    for (final sel in ['#content', '.content', '.chapter-content', '.read-content', '#chaptercontent', '.txtnav']) {
      try {
        final el = body.querySelector(sel);
        if (el != null && el.text.trim().length > 100) {
          return el.innerHtml;
        }
      } catch (_) {}
    }
    return body.text;
  }
}
