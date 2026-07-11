import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import '../bridge/legado_engine_bridge.dart';
import '../config/engine_config.dart';
import '../data/builtin_book_sources.dart';
import '../engine/web_book.dart';
import '../models/book.dart';
import '../models/book_source.dart';
import '../models/chapter.dart';

/// 书源服务门面 — 委托 `WebBook` 编排，对齐 Legado 分层架构
class BookSourceService {
  final WebBook _webBook;

  BookSourceService({WebBook? webBook}) : _webBook = webBook ?? WebBook();

  WebBook get webBook => _webBook;

  /// 仅 `@js:` URL 模板需强制 Dart；`<js>` 规则由 Rust rquickjs 处理
  /// [operation]: search | toc | content | bookInfo | explore | all
  static bool needsDartEngine(BookSource source, {String operation = 'all'}) {
    bool urlNeedsDart(String s) => s.contains('@js:');

    switch (operation) {
      case 'search':
        return urlNeedsDart(source.ruleSearchUrl);
      case 'toc':
        return urlNeedsDart(source.ruleChapterUrl);
      case 'content':
        return false;
      case 'bookInfo':
        return false;
      case 'explore':
        return source.rawSourceJson.contains('@js:');
      default:
        return source.rawSourceJson.contains('@js:');
    }
  }

  /// 搜索书籍（Rust 引擎优先，失败或无结果回退 Dart/WebBook）
  Future<List<Map<String, String>>> search(
    BookSource source,
    String keyword,
  ) async {
    if (!needsDartEngine(source, operation: 'search') &&
        EngineConfig.useRust &&
        LegadoEngineBridge.isAvailable) {
      try {
        final results = await LegadoEngineBridge.search(source, keyword);
        if (results.isNotEmpty) return results;
        debugPrint('  ⚠ Rust 搜索无结果，回退 Dart');
      } catch (e) {
        debugPrint('  ⚠ Rust 搜索失败，回退 Dart: $e');
      }
    }

    return _webBook.searchBook(source, keyword);
  }

  /// 获取章节列表（Rust 优先，JS 书源回退 Dart）
  Future<List<Chapter>> getChapters(
    Book book, {
    required BookSource source,
  }) async {
    if (!needsDartEngine(source, operation: 'toc') &&
        EngineConfig.useRust &&
        LegadoEngineBridge.isAvailable) {
      try {
        var chapters = await LegadoEngineBridge.getToc(source, book);
        if (chapters.isEmpty) {
          // JSON 书源 tocUrl 含 <js> 时 Rust 会先走 book_info；Dart 侧再兜底一次
          final info = await getBookInfo(source, book.sourceUrl);
          final tocUrl = info['tocUrl'] ?? '';
          if (tocUrl.isNotEmpty && tocUrl != book.sourceUrl) {
            chapters = await LegadoEngineBridge.getToc(
              source,
              book.copyWith(sourceUrl: tocUrl),
            );
          }
        }
        if (chapters.isNotEmpty) {
          debugPrint('  ✓ Rust 目录: ${chapters.length} 章');
          return chapters;
        }
        debugPrint('  ⚠ Rust 目录为空，回退 Dart');
      } catch (e) {
        debugPrint('  ⚠ Rust 目录失败，回退 Dart: $e');
      }
    }
    return _webBook.getChapterList(book: book, source: source);
  }

  /// 获取章节正文（Rust 优先，JS 书源回退 Dart）
  Future<String> getChapterContent(
    String url, {
    required BookSource source,
  }) async {
    if (!needsDartEngine(source, operation: 'content') &&
        EngineConfig.useRust &&
        LegadoEngineBridge.isAvailable) {
      try {
        final content = await LegadoEngineBridge.getContent(source, url);
        if (content.isNotEmpty && !content.startsWith('（此章节暂无内容）')) {
          debugPrint('  ✓ Rust 正文: ${content.length} 字符');
          return content;
        }
        debugPrint('  ⚠ Rust 正文为空，回退 Dart');
      } catch (e) {
        debugPrint('  ⚠ Rust 正文失败，回退 Dart: $e');
      }
    }
    return _webBook.getContent(url: url, source: source);
  }

  /// 发现页（Rust 优先，JS 书源回退 Dart）
  Future<List<Map<String, String>>> explore(
    BookSource source,
    String exploreUrl, {
    int page = 1,
  }) async {
    if (!needsDartEngine(source, operation: 'explore') &&
        EngineConfig.useRust &&
        LegadoEngineBridge.isAvailable) {
      try {
        final results =
            await LegadoEngineBridge.explore(source, exploreUrl, page: page);
        if (results.isNotEmpty) return results;
      } catch (e) {
        debugPrint('  ⚠ Rust 发现页失败，回退 Dart: $e');
      }
    }
    // Dart 发现页尚未实现，返回空
    return [];
  }

  /// 书籍详情（Rust 优先，JS 书源回退 Dart）
  Future<Map<String, String>> getBookInfo(
    BookSource source,
    String bookUrl,
  ) async {
    if (!needsDartEngine(source, operation: 'bookInfo') &&
        EngineConfig.useRust &&
        LegadoEngineBridge.isAvailable) {
      try {
        final info = await LegadoEngineBridge.getBookInfo(source, bookUrl);
        if (info['name']?.isNotEmpty == true) {
          return info;
        }
      } catch (e) {
        debugPrint('  ⚠ Rust 书籍详情失败: $e');
      }
    }
    return {};
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
