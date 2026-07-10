import 'package:flutter/foundation.dart';

import '../models/book.dart';
import '../models/book_source.dart';
import '../models/chapter.dart';
import 'analyze_url.dart';
import 'http/book_http_client.dart';
import 'parsers/book_chapter_list.dart';
import 'parsers/book_content.dart';
import 'parsers/book_list.dart';

/// 网络书编排入口 — 对齐 Legado `WebBook.kt`
class WebBook {
  final BookHttpClient http;

  WebBook({BookHttpClient? http}) : http = http ?? BookHttpClient();

  /// 搜索书籍
  Future<List<Map<String, String>>> searchBook(
    BookSource source,
    String keyword,
  ) async {
    if (source.ruleSearchUrl.isEmpty) return [];

    try {
      final cfg = await AnalyzeUrl.resolveSearchRequest(source, keyword);
      if (cfg.url.isEmpty) return [];

      var resolvedUrl = cfg.url;
      if (!resolvedUrl.startsWith('http')) {
        resolvedUrl = AnalyzeUrl.resolveUrl(resolvedUrl, source.bookSourceUrl);
      }

      debugPrint('🔍 ${source.bookSourceName}: ${cfg.method} $resolvedUrl');
      final rawBytes = await http.executeRequest(
        resolvedUrl,
        method: cfg.method,
        body: cfg.body,
        charset: cfg.charset,
        source: source,
      );

      final body = await http.decodeResponse(rawBytes, charset: cfg.charset);
      debugPrint('  ▸ 响应大小: ${body.length} 字符');

      return BookList.analyzeSearchResponse(
        body: body,
        source: source,
        keyword: keyword,
      );
    } catch (e) {
      debugPrint('  ✗ ${source.bookSourceName} 搜索出错: $e');
      return [];
    }
  }

  /// 获取目录
  Future<List<Chapter>> getChapterList({
    required Book book,
    required BookSource source,
  }) async {
    try {
      return await BookChapterList.getChapterList(
        book: book,
        source: source,
        http: http,
      );
    } catch (e) {
      debugPrint('获取章节列表出错: $e');
      return [];
    }
  }

  /// 获取正文
  Future<String> getContent({
    required String url,
    required BookSource source,
  }) async {
    try {
      return await BookContent.getContent(
        url: url,
        source: source,
        http: http,
      );
    } catch (e) {
      return '（加载失败: $e）';
    }
  }
}
