import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import '../bridge/legado_engine_bridge.dart';
import '../data/builtin_book_sources.dart';
import '../models/book.dart';
import '../models/book_source.dart';
import '../models/chapter.dart';

/// 书源服务门面 — 全部书源操作走 Rust 引擎（Phase E-B：无 Dart 回退）
class BookSourceService {
  BookSourceService();

  /// 历史 API：Rust 已覆盖全部操作，恒为 false
  static bool needsDartEngine(BookSource source, {String operation = 'all'}) =>
      false;

  void _requireRust() {
    if (!LegadoEngineBridge.isAvailable) {
      throw StateError('Rust 引擎未加载，请编译 legado_engine 后重试');
    }
  }

  /// 搜索书籍
  Future<List<Map<String, String>>> search(
    BookSource source,
    String keyword,
  ) async {
    _requireRust();
    final results = await LegadoEngineBridge.search(source, keyword);
    debugPrint('  ✓ Rust 搜索: ${results.length} 条');
    return results;
  }

  /// 获取章节列表
  Future<List<Chapter>> getChapters(
    Book book, {
    required BookSource source,
  }) async {
    _requireRust();
    // 先拉详情：ruleBookInfo.init 等 JS 会写入 cache（如番茄 articleid）
    final info = await getBookInfo(source, book.sourceUrl);
    final tocUrl = info['tocUrl'] ?? '';
    final tocBook = (tocUrl.isNotEmpty && tocUrl != book.sourceUrl)
        ? book.copyWith(sourceUrl: tocUrl)
        : book;
    final chapters = await LegadoEngineBridge.getToc(source, tocBook);
    debugPrint('  ✓ Rust 目录: ${chapters.length} 章');
    return chapters;
  }

  /// 获取章节正文
  Future<String> getChapterContent(
    String url, {
    required BookSource source,
  }) async {
    _requireRust();
    final content = await LegadoEngineBridge.getContent(source, url);
    debugPrint('  ✓ Rust 正文: ${content.length} 字符');
    return content;
  }

  /// 发现页
  Future<List<Map<String, String>>> explore(
    BookSource source,
    String exploreUrl, {
    int page = 1,
  }) async {
    _requireRust();
    return LegadoEngineBridge.explore(source, exploreUrl, page: page);
  }

  /// 书籍详情
  Future<Map<String, String>> getBookInfo(
    BookSource source,
    String bookUrl,
  ) async {
    _requireRust();
    return LegadoEngineBridge.getBookInfo(source, bookUrl);
  }

  /// 搜索结果转 Book 对象
  List<Book> resultsToBooks(
    List<Map<String, String>> results,
    String sourceUrl,
  ) {
    return results
        .map(
          (r) => Book(
            id: '${sourceUrl}_${r['url'].hashCode}',
            name: r['name'] ?? '未知书名',
            author: r['author'] ?? '',
            coverUrl: r['coverUrl'] ?? '',
            sourceUrl: r['url'] ?? '',
            description: r['note'] ?? '',
            bookSourceUrl: sourceUrl,
          ),
        )
        .toList();
  }

  // ── 书源市场 ──

  static List<BookSource>? _builtInCache;

  static Future<List<BookSource>> loadBuiltInSources() async {
    if (_builtInCache != null) return _builtInCache!;
    _builtInCache = await BuiltinBookSources.load();
    return _builtInCache!;
  }

  static Map<String, List<BookSource>> sourceMarketFrom(
    List<BookSource> sources,
  ) {
    final market = <String, List<BookSource>>{};
    for (final s in sources) {
      market.putIfAbsent(s.bookSourceGroup, () => []).add(s);
    }
    market['📥 从社区导入'] = [];
    return market;
  }

  /// 从 URL 获取书源 JSON 并解析
  static Future<List<BookSource>> fetchSourcesFromUrl(String url) async {
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
                'AppleWebKit/537.36 (KHTML, like Gecko) '
                'Chrome/131.0.0.0 Safari/537.36',
            'Accept': 'application/json, text/plain, */*',
          },
        ),
      );
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        },
      );

      final response = await dio.get(url);
      dynamic data = response.data;

      if (data is String) {
        final body = data.trim();
        if (body.startsWith('[') || body.startsWith('{')) {
          data = jsonDecode(body);
        }
      }

      List<dynamic>? sourceList;
      if (data is List) {
        sourceList = data;
      } else if (data is Map) {
        for (final key in [
          'data',
          'sources',
          'result',
          'bookSources',
          'items',
          'records',
        ]) {
          final val = data[key];
          if (val is List) {
            sourceList = val;
            break;
          }
        }
      }

      if (sourceList == null || sourceList.isEmpty) {
        debugPrint('从 $url 获取书源: 未找到书源数据');
        return [];
      }

      final sources = <BookSource>[];
      for (final item in sourceList) {
        if (item is! Map) continue;
        try {
          final src = BookSource.fromJson(Map<String, dynamic>.from(item));
          sources.add(src);
        } catch (_) {}
      }
      debugPrint('从 $url 获取书源: 成功导入 ${sources.length}/${sourceList.length} 个');
      return sources;
    } catch (e) {
      debugPrint('从网络获取书源失败: $e');
      return [];
    }
  }
}
