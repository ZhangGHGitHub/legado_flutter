import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' show parse;

import '../../models/book.dart';
import '../../models/book_source.dart';
import '../../models/chapter.dart';
import '../../services/rule_engine.dart';
import '../analyze_url.dart';
import '../http/book_http_client.dart';

/// 目录解析 — 对齐 Legado `BookChapterList.kt`
class BookChapterList {
  BookChapterList._();

  static Future<List<Chapter>> getChapterList({
    required Book book,
    required BookSource source,
    required BookHttpClient http,
  }) async {
    if (book.sourceUrl.isEmpty) return [];

    if (source.isJsonApiSource && source.ruleBookInfoTocUrl.isNotEmpty) {
      try {
        return await _getJsonApiChapters(book, source, http);
      } catch (e) {
        debugPrint('  ⚠ JSON API 章节获取失败，回退 HTML: $e');
      }
    }

    var fetchUrl = book.sourceUrl;
    if (source.ruleBookInfoTocUrl.isNotEmpty) {
      final resolved = await AnalyzeUrl.resolveHtmlTocUrl(book, source);
      if (resolved.isNotEmpty) {
        fetchUrl = resolved;
        if (fetchUrl != book.sourceUrl) {
          debugPrint('  ▸ 目录页 URL: $fetchUrl');
        }
      }
    }

    debugPrint('📖 获取章节: $fetchUrl');
    final results = await fetchHtmlChaptersPaged(
      source: source,
      http: http,
      startUrl: fetchUrl,
    );
    final baseUrl = AnalyzeUrl.baseUrl(fetchUrl);

    final chapters = results.asMap().entries.map((entry) {
      final i = entry.key;
      final r = entry.value;
      return Chapter(
        id: '${book.id}_ch_$i',
        bookId: book.id,
        title: r['title'] ?? '第${i + 1}章',
        index: i,
        url: RuleEngine.resolveUrl(r['url'] ?? '', baseUrl),
      );
    }).toList();
    debugPrint('  √ 章节列表: ${chapters.length} 章');
    return chapters;
  }

  static Future<List<Chapter>> _getJsonApiChapters(
    Book book,
    BookSource source,
    BookHttpClient http,
  ) async {
    var articleId = '';
    final urlMatch = RegExp(r'/(\d+)(?:/|$|\.)').firstMatch(book.sourceUrl);
    if (urlMatch != null) {
      articleId = urlMatch.group(1)!;
      debugPrint('  >> 从 URL 提取 articleid: $articleId');
    }

    if (articleId.isEmpty) {
      final detailBytes = await http.fetchBytes(book.sourceUrl, source);
      final detailStr = await http.decodeResponse(detailBytes);
      final detailData = jsonDecode(detailStr);
      articleId = JsonPath.resolveString(detailData, 'data.articleid');
    }

    var tocUrl = source.ruleBookInfoTocUrl;
    if (tocUrl.contains('<js>')) {
      tocUrl = await AnalyzeUrl.evaluateJsTemplate(
        tocUrl,
        book.sourceUrl,
        articleId,
      );
      debugPrint('  >> JS 模板执行结果: $tocUrl');
    } else {
      if (tocUrl.contains('{{result.articleid}}')) {
        tocUrl = tocUrl.replaceAll('{{result.articleid}}', articleId);
      }
      if (!tocUrl.startsWith('http')) {
        tocUrl = AnalyzeUrl.resolveUrl(tocUrl, source.bookSourceUrl);
      }
    }

    final ruleCtx = RuleContext.fromSource(
      source,
      baseUrl: AnalyzeUrl.baseUrl(source.bookSourceUrl),
      bookUrl: book.sourceUrl,
    );
    if (articleId.isNotEmpty) ruleCtx.putCache('articleid', articleId);

    Future<String> resolveChapterUrl({
      required String template,
      required dynamic item,
      required String rawValue,
    }) async {
      var resolved = template;
      if (resolved.contains('{{')) {
        resolved = JsonPath.resolveTemplate(resolved, item);
      }
      final fullJs = resolved.contains('result')
          ? resolved.replaceAll('result', "'$rawValue'")
          : resolved;
      final url = await AnalyzeUrl.evaluateJsTemplate(
        fullJs,
        source.bookSourceUrl,
        articleId,
      );
      return url.isNotEmpty ? url : rawValue;
    }

    final merged = <Map<String, String>>[];
    final visitedPages = <String>{};
    var currentUrl = tocUrl;
    var page = 0;
    const maxPages = 50;

    while (currentUrl.isNotEmpty && page < maxPages) {
      page++;
      if (visitedPages.contains(currentUrl)) break;
      visitedPages.add(currentUrl);

      debugPrint('  >> 章节 API URL (页$page): $currentUrl');
      final tocBytes = await http.fetchBytes(currentUrl, source);
      final tocStr = await http.decodeResponse(tocBytes);
      final tocData = jsonDecode(tocStr);
      ruleCtx.result = tocData;

      final batch = await RuleEngine.parseJsonChapters(
        tocData,
        source: source,
        ctx: ruleCtx,
        articleId: articleId,
        resolveChapterUrl: resolveChapterUrl,
      );
      merged.addAll(batch);

      final nextRule = source.ruleTocNextTocUrl;
      if (nextRule.isEmpty) break;
      var nextUrl = RuleEngine.extractJsonNextUrl(
        tocData,
        nextUrlRule: nextRule,
        ctx: ruleCtx,
      );
      if (nextUrl.isEmpty) break;
      if (!nextUrl.startsWith('http')) {
        nextUrl = AnalyzeUrl.resolveUrl(nextUrl, source.bookSourceUrl);
      }
      if (visitedPages.contains(nextUrl)) break;
      currentUrl = nextUrl;
    }

    return merged.asMap().entries.map((entry) {
      final i = entry.key;
      final r = entry.value;
      return Chapter(
        id: '${book.id}_ch_$i',
        bookId: book.id,
        title: r['title'] ?? '第${i + 1}章',
        index: i,
        url: r['url'] ?? '',
      );
    }).toList();
  }

  static Future<List<Map<String, String>>> fetchHtmlChaptersPaged({
    required BookSource source,
    required BookHttpClient http,
    required String startUrl,
  }) async {
    final merged = <Map<String, String>>[];
    final seen = <String>{};
    final visitedPages = <String>{};
    var currentUrl = startUrl;
    final baseUrl = AnalyzeUrl.baseUrl(startUrl);
    var page = 0;
    const maxPages = 50;
    final ruleCtx = RuleContext.fromSource(
      source,
      baseUrl: baseUrl,
      bookUrl: startUrl,
    );

    while (currentUrl.isNotEmpty && page < maxPages) {
      page++;
      final pageKey = RuleEngine.resolveUrl(currentUrl, baseUrl);
      if (visitedPages.contains(pageKey)) {
        debugPrint('  ▸ 目录页重复，停止分页');
        break;
      }
      visitedPages.add(pageKey);
      debugPrint('  ▸ 目录页 $page: $currentUrl');

      Uint8List rawBytes;
      var retries = 0;
      const maxRetries = 3;
      while (true) {
        rawBytes = await http.fetchBytes(currentUrl, source);
        if (rawBytes.isEmpty && retries < maxRetries - 1) {
          retries++;
          debugPrint('  ⚠ 空响应，${retries * 2}秒后重试($retries/$maxRetries)...');
          await Future.delayed(Duration(seconds: retries * 2));
          continue;
        }
        break;
      }

      final body = await http.decodeResponse(rawBytes);
      final document = parse(body);
      final batch = RuleEngine.parseChapters(
        document,
        source: source,
        ctx: ruleCtx,
      );

      var added = 0;
      for (final ch in batch) {
        final rel = ch['url'] ?? '';
        if (rel.isEmpty) continue;
        final abs = RuleEngine.resolveUrl(rel, baseUrl);
        if (seen.contains(abs)) continue;
        seen.add(abs);
        merged.add({'title': ch['title'] ?? '', 'url': rel});
        added++;
      }
      debugPrint('  ▸ 本页新增 $added 章，累计 ${merged.length} 章');

      if (added == 0 && merged.isNotEmpty) {
        debugPrint('  ▸ 本页无新章节，停止分页');
        break;
      }

      final next = RuleEngine.extractNextTocUrl(
        document,
        source: source,
        baseUrl: baseUrl,
        ctx: ruleCtx,
      );
      if (next.isEmpty) break;
      final nextKey = RuleEngine.resolveUrl(next, baseUrl);
      if (nextKey == pageKey || visitedPages.contains(nextKey)) break;
      currentUrl = next;
    }

    return merged;
  }
}
