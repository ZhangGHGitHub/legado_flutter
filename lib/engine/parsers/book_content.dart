import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' show parse;

import '../../models/book_source.dart';
import '../../services/js_evaluator.dart';
import '../../services/rule_engine.dart';
import '../analyze_url.dart';
import '../http/book_http_client.dart';

/// 正文解析 — 对齐 Legado `BookContent.kt`
class BookContent {
  BookContent._();

  static Future<String> getContent({
    required String url,
    required BookSource source,
    required BookHttpClient http,
  }) async {
    if (source.isJsonApiSource && source.ruleContentPath.isNotEmpty) {
      try {
        return await _getJsonApiContent(url, source, http);
      } catch (e) {
        debugPrint('  ⚠ JSON API 正文获取失败，回退 HTML: $e');
      }
    }
    return fetchHtmlContent(source: source, http: http, url: url);
  }

  static Future<String> fetchHtmlContent({
    required BookSource source,
    required BookHttpClient http,
    required String url,
  }) async {
    var contentUrl = url;
    if (source.ruleContentUrl.isNotEmpty) {
      contentUrl = source.ruleContentUrl.replaceAll('{{url}}', url);
      if (contentUrl.contains('<js>')) {
        contentUrl = await AnalyzeUrl.evaluateJsTemplate(
          contentUrl,
          source.bookSourceUrl,
          url,
        );
      }
      if (!contentUrl.startsWith('http')) {
        contentUrl = AnalyzeUrl.resolveUrl(contentUrl, source.bookSourceUrl);
      }
    }

    final baseUrl = AnalyzeUrl.baseUrl(contentUrl);
    final parts = <String>[];
    final visited = <String>{};
    var currentUrl = contentUrl;
    var page = 0;
    const maxPages = 20;
    final ruleCtx = RuleContext.fromSource(
      source,
      baseUrl: baseUrl,
      chapterUrl: url,
    );

    while (currentUrl.isNotEmpty && page < maxPages) {
      page++;
      final pageKey = RuleEngine.resolveUrl(currentUrl, baseUrl);
      if (visited.contains(pageKey)) break;
      visited.add(pageKey);

      debugPrint('📖 获取正文${page > 1 ? " (第$page 页)" : ""}: $currentUrl');
      final rawBytes = await http.fetchBytes(currentUrl, source);
      final body = await http.decodeResponse(rawBytes);
      final document = parse(body);
      final chunk = RuleEngine.parseContent(
        document,
        source: source,
        ctx: ruleCtx,
      );
      if (chunk.isNotEmpty) parts.add(chunk);

      final next = RuleEngine.extractNextContentUrl(
        document,
        source: source,
        baseUrl: baseUrl,
        currentUrl: currentUrl,
        ctx: ruleCtx,
      );
      if (next.isEmpty || visited.contains(next)) break;
      currentUrl = next;
    }

    final content = parts.join('\n\n').trim();
    debugPrint('  √ 正文长度: ${content.length} 字符');
    return content.isNotEmpty ? content : '（此章节暂无内容）';
  }

  static Future<String> _getJsonApiContent(
    String url,
    BookSource source,
    BookHttpClient http,
  ) async {
    var contentUrl = url;
    if (source.ruleContentUrl.isNotEmpty) {
      contentUrl = source.ruleContentUrl.replaceAll('{{url}}', url);
      if (contentUrl.contains('<js>')) {
        contentUrl = await AnalyzeUrl.evaluateJsTemplate(
          contentUrl,
          source.bookSourceUrl,
          url,
        );
      }
    }

    String? bodyJs;
    final commaIdx = contentUrl.indexOf(',');
    if (commaIdx > 0 && contentUrl.indexOf('{', commaIdx) == commaIdx + 1) {
      final urlPart = contentUrl.substring(0, commaIdx);
      final jsonPart = contentUrl.substring(commaIdx + 1);
      try {
        final opts = jsonDecode(jsonPart);
        if (opts is Map) {
          bodyJs = opts['bodyJs'] as String?;
          final jsStr = opts['js'] as String?;
          if (jsStr != null && jsStr.isNotEmpty) {
            try {
              final jsEval = JsEvaluatorService();
              final jsResult = jsEval.runScript('var url = "$url"; $jsStr');
              if (jsResult.isNotEmpty) contentUrl = jsResult;
            } catch (_) {}
          }
        }
      } catch (_) {}
      contentUrl = urlPart;
    }

    if (!contentUrl.startsWith('http')) {
      contentUrl = AnalyzeUrl.resolveUrl(contentUrl, source.bookSourceUrl);
    }

    final ruleCtx = RuleContext.fromSource(
      source,
      baseUrl: AnalyzeUrl.baseUrl(source.bookSourceUrl),
      chapterUrl: url,
    );
    final parts = <String>[];
    final visited = <String>{};
    var currentUrl = contentUrl;
    var page = 0;
    const maxPages = 20;

    while (currentUrl.isNotEmpty && page < maxPages) {
      page++;
      if (visited.contains(currentUrl)) break;
      visited.add(currentUrl);

      debugPrint(
        '📖 获取正文 (JSON API${page > 1 ? " 第$page 页" : ""}): $currentUrl',
      );
      final bytes = await http.fetchBytes(currentUrl, source);
      var body = await http.decodeResponse(bytes);

      if (bodyJs != null && bodyJs.isNotEmpty) {
        try {
          final jsEval = JsEvaluatorService();
          final jsResult = jsEval.eval(bodyJs, {'result': body});
          if (jsResult.isNotEmpty) {
            final decoded = jsonDecode(jsResult);
            if (decoded is String) body = decoded;
          }
        } catch (_) {}
      }

      final data = jsonDecode(body);
      ruleCtx.result = data;

      final chunk = await RuleEngine.parseJsonContentPage(
        data,
        source: source,
        ctx: ruleCtx,
        cleanContent: (js, raw) =>
            AnalyzeUrl.evaluateContentJs(js, raw, source),
      );
      if (chunk.isNotEmpty) parts.add(chunk);

      final nextRule = source.ruleContentNextContentUrl;
      if (nextRule.isEmpty) break;
      var nextUrl = RuleEngine.extractJsonNextUrl(
        data,
        nextUrlRule: nextRule,
        ctx: ruleCtx,
      );
      if (nextUrl.isEmpty) break;
      if (!nextUrl.startsWith('http')) {
        nextUrl = AnalyzeUrl.resolveUrl(nextUrl, source.bookSourceUrl);
      }
      if (visited.contains(nextUrl)) break;
      currentUrl = nextUrl;
    }

    final content = parts.join('\n\n').trim();
    return content.isNotEmpty ? content : '（此章节暂无内容）';
  }
}
