import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/dict_rule.dart';
import '../utils/ssrf_guard.dart';

/// 轻量字典规则测试 — 对齐 Jingshiro [DictRule.search] 的简化路径：
/// - 替换 `{{key}}`
/// - 解析 URL 后可选 `,jsonOptions`（method/headers/body）
/// - `showRule` 为空时返回响应体；含 `@js:` 时附注说明并返回原文
class DictRuleTester {
  DictRuleTester._();

  static Future<String> test(DictRule rule, String word) async {
    final key = word.trim();
    if (key.isEmpty) {
      throw ArgumentError('请输入测试词');
    }
    var urlRule = rule.urlRule.trim();
    if (urlRule.isEmpty) {
      throw ArgumentError('URL 规则为空');
    }
    if (urlRule.startsWith('@js:') || urlRule.startsWith('<js>')) {
      return '当前 Flutter 端尚未执行完整 JS/AnalyzeUrl 引擎。\n'
          '请先保存规则；阅读器查词将在规则引擎就绪后生效。\n'
          'URL 规则以 @js 开头，无法用简化 HTTP 测试。';
    }

    urlRule = _replaceKey(urlRule, key);
    urlRule = urlRule.replaceAll('{{java.getWebViewUA()}}', _kUa);
    urlRule = urlRule.replaceAll(r'${java.getWebViewUA()}', _kUa);

    final parsed = _parseUrlRule(urlRule);
    SsrfGuard.assertPublicHttpUrl(parsed.url);

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        followRedirects: true,
        maxRedirects: SsrfGuard.maxRedirects,
        validateStatus: (s) => s != null && s < 500,
        headers: {
          'User-Agent': _kUa,
          ...parsed.headers,
        },
      ),
    );

    final Response<String> resp;
    final method = parsed.method.toUpperCase();
    if (method == 'POST') {
      resp = await dio.post<String>(
        parsed.url,
        data: parsed.body,
        options: Options(
          contentType: parsed.contentType,
          responseType: ResponseType.plain,
        ),
      );
    } else {
      resp = await dio.get<String>(
        parsed.url,
        options: Options(responseType: ResponseType.plain),
      );
    }

    final body = resp.data ?? '';
    final show = rule.showRule.trim();
    if (show.isEmpty) {
      return body;
    }
    if (show.contains('@js:') || show.startsWith('<js>')) {
      final preview = body.length > 4000 ? '${body.substring(0, 4000)}…' : body;
      return '【简化测试】已请求 URL，但 showRule 含 JS，未能完整解析。\n'
          '响应预览：\n$preview';
    }
    if (show.toLowerCase().contains('tag.body') ||
        show.toLowerCase().contains('@text') ||
        show.toLowerCase().contains('@all')) {
      return _stripHtmlRough(body);
    }
    final preview = body.length > 4000 ? '${body.substring(0, 4000)}…' : body;
    return '【简化测试】未识别的 showRule「$show」，返回响应原文：\n$preview';
  }

  static const _kUa =
      'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

  static String _replaceKey(String s, String key) {
    final enc = Uri.encodeQueryComponent(key);
    return s
        .replaceAll('{{key}}', enc)
        .replaceAll('{{ key }}', enc)
        .replaceAll(r'${key}', enc);
  }

  static _ParsedUrl _parseUrlRule(String raw) {
    final comma = _findOptionsComma(raw);
    if (comma < 0) {
      return _ParsedUrl(url: raw.trim(), method: 'GET');
    }
    final url = raw.substring(0, comma).trim();
    final optRaw = raw.substring(comma + 1).trim();
    Map<String, dynamic> opts = {};
    try {
      opts = Map<String, dynamic>.from(jsonDecode(optRaw) as Map);
    } catch (_) {
      return _ParsedUrl(url: raw.trim(), method: 'GET');
    }
    final headers = <String, String>{};
    final h = opts['headers'];
    if (h is Map) {
      h.forEach((k, v) {
        if (k != null && v != null) headers['$k'] = '$v';
      });
    }
    return _ParsedUrl(
      url: url,
      method: (opts['method'] as String?) ?? 'GET',
      body: opts['body']?.toString(),
      headers: headers,
      contentType: headers['Content-Type'] ??
          headers['content-type'] ??
          'application/x-www-form-urlencoded',
    );
  }

  /// Legado URL 格式：`https://host/path,{json}` — 找第一个不在引号内的逗号后跟 `{`
  static int _findOptionsComma(String raw) {
    for (var i = 0; i < raw.length - 1; i++) {
      if (raw[i] == ',' && raw[i + 1] == '{') {
        return i;
      }
    }
    return -1;
  }

  static String _stripHtmlRough(String html) {
    var s = html
        .replaceAll(RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'<[^>]+>'), ' ');
    s = s
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"');
    s = s.replaceAll(RegExp(r'[ \t\f\v]+'), ' ');
    s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return s.trim();
  }
}

class _ParsedUrl {
  final String url;
  final String method;
  final String? body;
  final Map<String, String> headers;
  final String contentType;

  const _ParsedUrl({
    required this.url,
    required this.method,
    this.body,
    this.headers = const {},
    this.contentType = 'application/x-www-form-urlencoded',
  });
}
