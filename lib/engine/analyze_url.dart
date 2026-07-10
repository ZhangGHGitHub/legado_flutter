import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/book.dart';
import '../models/book_source.dart';
import '../services/js_evaluator.dart';

/// Legado URL 配置 — 对应 `AnalyzeUrl` 的 URL 模板部分
class RequestConfig {
  final String url;
  final String method;
  final String? body;
  final String charset;

  const RequestConfig({
    required this.url,
    this.method = 'GET',
    this.body,
    this.charset = 'UTF-8',
  });
}

/// URL 解析与 JS 模板 — 对齐 Legado `AnalyzeUrl.kt`（请求构造层）
class AnalyzeUrl {
  AnalyzeUrl._();

  static String baseUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return '';
    return '${uri.scheme}://${uri.host}${uri.port == 80 || uri.port == 443 ? '' : ':${uri.port}'}';
  }

  static String resolveUrl(String url, String base) {
    if (url.startsWith('http')) return url;
    final root = baseUrl(base);
    if (url.startsWith('/')) return '$root$url';
    return '$root/$url';
  }

  static bool hasNonAscii(String s) => s.codeUnits.any((c) => c > 127);

  /// 解析 Legado JSON 格式 URL
  static RequestConfig parseUrlConfig(String rawUrl, String keyword) {
    rawUrl = rawUrl.trim();

    String urlPart;
    String? jsonPart;

    if (!rawUrl.startsWith('{')) {
      final commaIdx = rawUrl.indexOf(',');
      if (commaIdx > 0 && rawUrl.indexOf('{', commaIdx) == commaIdx + 1) {
        urlPart = rawUrl.substring(0, commaIdx);
        jsonPart = rawUrl.substring(commaIdx + 1);
      } else {
        urlPart = rawUrl;
      }
    } else {
      urlPart = '';
      jsonPart = rawUrl;
    }

    var method = 'GET';
    var charset = 'UTF-8';
    String? bodyStr;

    if (jsonPart != null) {
      try {
        final cfg = jsonDecode(jsonPart) as Map<String, dynamic>;
        method = (cfg['method'] as String?)?.toUpperCase() ?? 'GET';
        charset = ((cfg['charset'] as String?) ?? '').toUpperCase();
        bodyStr = cfg['body'] as String?;
      } catch (e) {
        debugPrint('  ⚠ 解析 ruleSearchUrl JSON 失败: $e');
      }
    }

    var finalUrl = urlPart
        .replaceAll('{{key}}', Uri.encodeComponent(keyword))
        .replaceAll('{{page}}', '1')
        .replaceAll('{{limit}}', '20');

    if (bodyStr != null) {
      bodyStr = bodyStr
          .replaceAll('{{key}}', keyword)
          .replaceAll('{{page}}', '1')
          .replaceAll('{{limit}}', '20');
    }

    if (charset.isEmpty) {
      charset = (bodyStr != null && hasNonAscii(bodyStr)) ? '936' : 'UTF-8';
    }

    return RequestConfig(
      url: finalUrl,
      method: method,
      body: bodyStr,
      charset: charset,
    );
  }

  static Future<RequestConfig> resolveSearchRequest(
    BookSource source,
    String keyword,
  ) async {
    var raw = source.ruleSearchUrl.trim();
    if (raw.isEmpty) return const RequestConfig(url: '');

    if (raw.startsWith('@js:') || raw.startsWith('@Js:')) {
      final jsCode = raw.substring(4).trim();
      final url = await evaluateSearchJs(jsCode, source, keyword);
      if (url.isNotEmpty) return RequestConfig(url: url);
      return const RequestConfig(url: '');
    }

    if (raw.contains('<js>')) {
      final resolved = await evaluateJsTemplate(
        raw.replaceAll('{{key}}', keyword).replaceAll('{{page}}', '1'),
        source.bookSourceUrl,
        '',
        keyword: keyword,
        jsLib: source.jsLib.isNotEmpty ? source.jsLib : null,
      );
      if (resolved.isNotEmpty) {
        return parseUrlConfig(resolved, keyword);
      }
    }

    return parseUrlConfig(raw, keyword);
  }

  static Future<String> evaluateSearchJs(
    String jsCode,
    BookSource source,
    String keyword,
  ) async {
    try {
      final jsEval = JsEvaluatorService();
      final base = baseUrl(source.bookSourceUrl);
      final wrapped =
          '''
var key = ${jsonEncode(keyword)};
var page = 1;
var baseUrl = ${jsonEncode(source.bookSourceUrl)};
function Base() { return ${jsonEncode(base)}; }
${source.jsLib}

$jsCode''';
      return jsEval.runScript(wrapped);
    } catch (e) {
      debugPrint('  >> 搜索 JS 执行失败: $e');
      return '';
    }
  }

  static Future<String> evaluateJsTemplate(
    String template,
    String bookUrl,
    String articleId, {
    Map<String, dynamic>? resultData,
    String? jsLib,
    String? keyword,
  }) async {
    try {
      final jsMatch = RegExp(
        r'<js>(.*?)</js>',
        dotAll: true,
      ).firstMatch(template);
      if (jsMatch == null) return template;

      final jsCode = jsMatch.group(1)!;
      final base = baseUrl(bookUrl);
      final resultJson = (resultData != null)
          ? jsonEncode(resultData)
          : '{"articleid":"$articleId"}';
      final keyJson = jsonEncode(keyword ?? '');

      final wrappedCode =
          '''
var result = $resultJson;
var baseUrl = '$bookUrl';
var articleid = '$articleId';
var key = $keyJson;
var page = 1;
function J(obj) { return obj; }
function Base() { return '$base'; }
var cache = { _data: { 'articleid': '$articleId' },
  putMemory: function(key, val) { cache._data[key] = val; },
  getFromMemory: function(key) { return cache._data[key] || ''; }
};
${jsLib ?? ''}

$jsCode''';

      final jsEval = JsEvaluatorService();
      return jsEval.runScript(wrappedCode);
    } catch (e) {
      debugPrint('  >> JS 模板执行失败: $e');
      return template;
    }
  }

  static Future<String> evaluateContentJs(
    String template,
    String rawContent,
    BookSource source,
  ) async {
    try {
      final jsMatch = RegExp(
        r'<js>(.*?)</js>',
        dotAll: true,
      ).firstMatch(template);
      if (jsMatch == null) return rawContent;
      final jsCode = jsMatch.group(1)!;
      final base = baseUrl(source.bookSourceUrl);
      final escaped = rawContent
          .replaceAll('\\', '\\\\')
          .replaceAll("'", "\\'")
          .replaceAll('\n', '\\n')
          .replaceAll('\r', '\\r');

      final wrappedCode =
          '''
var result = '$escaped';
var baseUrl = '$base';
function Base() { return '$base'; }
function J(obj) { try { return JSON.parse(String(obj||'{}')); } catch(e) { return {}; } }
${source.jsLib}

$jsCode''';
      final jsEval = JsEvaluatorService();
      return jsEval.runScript(wrappedCode);
    } catch (e) {
      debugPrint('  >> 内容JS处理失败: $e');
      return rawContent;
    }
  }

  static Future<String> resolveHtmlTocUrl(Book book, BookSource source) async {
    var tocUrl = source.ruleBookInfoTocUrl.trim();
    if (tocUrl.isEmpty) return book.sourceUrl;

    var articleId = '';
    final urlMatch = RegExp(r'/(\d+)(?:/|$|\.)').firstMatch(book.sourceUrl);
    if (urlMatch != null) articleId = urlMatch.group(1)!;

    if (tocUrl.contains('<js>')) {
      final resolved = await evaluateJsTemplate(
        tocUrl,
        book.sourceUrl,
        articleId,
        jsLib: source.jsLib.isNotEmpty ? source.jsLib : null,
      );
      if (resolved.isNotEmpty) return resolveUrl(resolved, book.sourceUrl);
    }

    tocUrl = tocUrl
        .replaceAll('{{baseUrl}}', baseUrl(book.sourceUrl))
        .replaceAll('{{result.articleid}}', articleId)
        .replaceAll('{{articleid}}', articleId);

    if (!tocUrl.startsWith('http')) {
      return resolveUrl(tocUrl, book.sourceUrl);
    }
    return tocUrl;
  }
}
