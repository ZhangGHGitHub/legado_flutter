import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' show parse;

import '../../models/book_source.dart';
import '../analyze_url.dart';
import '../../services/rule_engine.dart';

/// 搜索/发现列表解析 — 对齐 Legado `BookList.kt`
class BookList {
  BookList._();

  static List<Map<String, String>> analyzeSearchResponse({
    required String body,
    required BookSource source,
    required String keyword,
  }) {
    dynamic data;
    try {
      data = jsonDecode(body);
      debugPrint('  ▸ JSON 解析成功');
    } catch (e) {
      debugPrint('  ▸ JSON 解析失败: $e');
    }

    final baseUrl = AnalyzeUrl.baseUrl(source.bookSourceUrl);

    if (data is Map || data is List) {
      if (source.isJsonApiSource) {
        final jsonStr = jsonEncode(data);
        final ruleCtx = RuleContext.fromSource(
          source,
          baseUrl: baseUrl,
          key: keyword,
          result: data,
        );
        final results = RuleEngine.parseJsonSearchResults(
          jsonStr,
          source: source,
          ctx: ruleCtx,
        );
        if (results.isNotEmpty) {
          return _normalizeResults(results, baseUrl);
        }
        debugPrint('  ▸ JSON API 返回空结果，回退 HTML 解析');
      } else {
        debugPrint(
          '  ⚠ ${source.bookSourceName}: 返回 JSON 但无 JSON 规则，尝试 HTML 解析',
        );
      }
    }

    final document = parse(body);
    final ruleCtx = RuleContext.fromSource(
      source,
      baseUrl: baseUrl,
      key: keyword,
      result: data,
    );
    final results = RuleEngine.parseSearchResults(
      document,
      source: source,
      ctx: ruleCtx,
    );
    return _normalizeResults(results, baseUrl);
  }

  static List<Map<String, String>> _normalizeResults(
    List<Map<String, String>> results,
    String baseUrl,
  ) {
    return results
        .map(
          (r) => {
            'name': r['name'] ?? '',
            'author': r['author'] ?? '',
            'url': RuleEngine.resolveUrl(r['url'] ?? '', baseUrl),
            'coverUrl': RuleEngine.resolveUrl(r['coverUrl'] ?? '', baseUrl),
            'kind': r['kind'] ?? '',
            'note': r['note'] ?? '',
          },
        )
        .toList();
  }
}
