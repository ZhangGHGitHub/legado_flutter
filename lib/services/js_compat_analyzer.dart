import 'dart:convert';

/// JS block / @js rule scan for source compatibility (REFACTOR_PLAN #2).
class JsCompatReport {
  final String sourceName;
  final String sourceUrl;
  final int atJsCount;
  final int jsBlockCount;
  final bool hasJsLib;
  final bool usesJsoup;
  final bool usesJavaAjax;
  final List<String> jsFields;

  const JsCompatReport({
    required this.sourceName,
    required this.sourceUrl,
    required this.atJsCount,
    required this.jsBlockCount,
    required this.hasJsLib,
    required this.usesJsoup,
    required this.usesJavaAjax,
    required this.jsFields,
  });

  bool get hasJsRules => atJsCount > 0 || jsBlockCount > 0 || hasJsLib;

  @override
  String toString() {
    return 'JsCompat($sourceName: @js=$atJsCount <js>=$jsBlockCount '
        'jsLib=$hasJsLib jsoup=$usesJsoup fields=${jsFields.length})';
  }
}

abstract final class JsCompatAnalyzer {
  static JsCompatReport scanJson(String rawJson) {
    final text = rawJson;
    final atJsPattern = RegExp(r'@js:', caseSensitive: false);
    final atJs = atJsPattern.allMatches(text).length;
    final jsBlockPattern = RegExp(r'<js>', caseSensitive: false);
    final jsBlocks = jsBlockPattern.allMatches(text).length;
    final hasJsLib = text.contains('"jsLib"') && !text.contains('"jsLib":""');
    final usesJsoup = text.contains('Packages.org.jsoup');
    final usesAjax = text.contains('java.ajax');

    String name = 'unknown';
    String url = '';
    try {
      final decoded = _decodeRoot(text);
      if (decoded is Map) {
        name = decoded['bookSourceName']?.toString() ?? name;
        url = decoded['bookSourceUrl']?.toString() ?? '';
      }
    } catch (_) {}

    final fields = <String>[];
    for (final key in [
      'searchUrl',
      'ruleSearch',
      'ruleExplore',
      'ruleBookInfo',
      'ruleToc',
      'ruleContent',
      'jsLib',
    ]) {
      if (key == 'jsLib') {
        if (hasJsLib) fields.add(key);
        continue;
      }
      final segment = _extractJsonKeyBlock(text, key);
      if (jsBlockPattern.hasMatch(segment) || atJsPattern.hasMatch(segment)) {
        fields.add(key);
      }
    }

    return JsCompatReport(
      sourceName: name,
      sourceUrl: url,
      atJsCount: atJs,
      jsBlockCount: jsBlocks,
      hasJsLib: hasJsLib,
      usesJsoup: usesJsoup,
      usesJavaAjax: usesAjax,
      jsFields: fields,
    );
  }

  static dynamic _decodeRoot(String raw) {
    final trimmed = raw.trimLeft().replaceFirst('\uFEFF', '');
    final decoded = jsonDecode(trimmed);
    if (decoded is List && decoded.isNotEmpty) {
      return decoded.first;
    }
    return decoded;
  }

  static String _extractJsonKeyBlock(String text, String key) {
    final pattern = RegExp('"$key"\\s*:\\s*');
    final match = pattern.firstMatch(text);
    if (match == null) return '';
    final end = (match.start + 400).clamp(0, text.length);
    return text.substring(match.start, end);
  }
}
