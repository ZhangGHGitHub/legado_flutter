import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/builtin_book_sources.dart';
import '../domain/ports/book_source_book_info_port.dart';
import '../domain/ports/book_source_content_port.dart';
import '../domain/ports/book_source_explore_port.dart';
import '../domain/ports/book_source_search_port.dart';
import '../domain/ports/book_source_toc_port.dart';
import '../domain/ports/public_text_fetch_port.dart';
import '../domain/ports/reader_content_source_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import '../utils/site_busy_guard.dart';

/// 书源服务门面 — 全部书源操作走 Rust 引擎（Phase E-B：无 Dart 回退）
class BookSourceService
    implements ReaderContentSourcePort, PaginatedReaderContentSourcePort {
  BookSourceService({
    required BookSourceSearchPort searchPort,
    required BookSourceBookInfoPort bookInfoPort,
    required BookSourceContentPort contentPort,
    required BookSourceExplorePort explorePort,
    required BookSourceTocPort tocPort,
    required PublicTextFetchPort publicTextPort,
  }) : _searchPort = searchPort,
       _bookInfoPort = bookInfoPort,
       _contentPort = contentPort,
       _explorePort = explorePort,
       _tocPort = tocPort,
       _publicTextPort = publicTextPort;

  final BookSourceSearchPort _searchPort;
  final BookSourceBookInfoPort _bookInfoPort;
  final BookSourceContentPort _contentPort;
  final BookSourceExplorePort _explorePort;
  final BookSourceTocPort _tocPort;
  final PublicTextFetchPort _publicTextPort;

  /// 搜索书籍
  Future<List<Map<String, String>>> search(
    BookSource source,
    String keyword,
  ) async {
    final results = await _searchPort.search(source, keyword);
    debugPrint('  ✓ Rust 搜索: ${results.length} 条');
    return results;
  }

  /// 获取章节列表（同 bookUrl 并发请求会合并；源站 DB 繁忙自动退避重试）
  Future<List<Chapter>> getChapters(
    Book book, {
    required BookSource source,
  }) async {
    final key =
        '${source.bookSourceUrl}\u0000${book.sourceUrl}\u0000${book.id}';
    return SiteBusyGuard.dedupeByKey(key, () {
      return SiteBusyGuard.retryOnBusy(() => _fetchChaptersOnce(book, source));
    });
  }

  Future<List<Chapter>> _fetchChaptersOnce(Book book, BookSource source) async {
    var tocUrl = book.tocUrl.trim();
    if (tocUrl.isEmpty) {
      // 仅在书籍未保存目录地址时拉详情，保留源站详情初始化副作用。
      final info = await getBookInfo(source, book.sourceUrl);
      tocUrl = info['tocUrl']?.trim() ?? '';
    }
    final tocBook = (tocUrl.isNotEmpty && tocUrl != book.sourceUrl)
        ? book.copyWith(sourceUrl: tocUrl)
        : book;
    final chapters = await _tocPort.getToc(source, tocBook);
    debugPrint('  ✓ Rust 目录: ${chapters.length} 章');
    return chapters;
  }

  /// 获取章节正文
  @override
  Future<String> getChapterContent(
    String url, {
    required BookSource source,
  }) async {
    try {
      final content = await _contentPort.getContent(source, url);
      debugPrint('  ✓ Rust 正文: ${content.length} 字符');
      return content;
    } catch (e) {
      debugPrint('  ✗ Rust 正文失败: $e');
      rethrow;
    }
  }

  @override
  Future<String> getChapterContentWithNextChapter(
    String url, {
    required BookSource source,
    String? nextChapterUrl,
  }) async {
    final contentPort = _contentPort;
    if (contentPort is! PaginatedBookSourceContentPort) {
      return getChapterContent(url, source: source);
    }
    try {
      final content = await (contentPort as PaginatedBookSourceContentPort)
          .getContentWithNextChapter(
            source,
            url,
            nextChapterUrl: nextChapterUrl,
          );
      debugPrint('  ✓ Rust 正文: ${content.length} 字符');
      return content;
    } catch (e) {
      debugPrint('  ✗ Rust 正文失败: $e');
      rethrow;
    }
  }

  /// 发现页
  Future<List<Map<String, String>>> explore(
    BookSource source,
    String exploreUrl, {
    int page = 1,
  }) async {
    return _explorePort.explore(source, exploreUrl, page: page);
  }

  /// 书籍详情
  Future<Map<String, String>> getBookInfo(
    BookSource source,
    String bookUrl,
  ) async {
    return _bookInfoPort.getBookInfo(source, bookUrl);
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
  Future<List<BookSource>> fetchSourcesFromUrl(String url) async {
    try {
      final rawBody = await _publicTextPort.fetch(url);
      if (rawBody.isEmpty) {
        debugPrint('从 $url 获取书源: 空响应');
        return [];
      }

      dynamic data;
      final trimmed = rawBody.trim();
      if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
        data = jsonDecode(trimmed);
      } else {
        if (trimmed.contains('地址不存在') || trimmed.contains('已失效')) {
          debugPrint('从 $url 获取书源: 分享链接已失效');
        } else {
          debugPrint('从 $url 获取书源: 非 JSON 响应 (${trimmed.length} chars)');
        }
        return [];
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
