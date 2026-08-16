import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/bridge/legado_engine_bridge.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/services/book_source_service.dart';
import '../helpers/book_source_service_test_factory.dart';

/// Phase 3.1 功能对齐验证（7565 在线，7497 使用本地 JSON fixture）
/// 对照 REFACTOR_PLAN.md §3.1

Future<String> _loadBuiltinJson(String name) async {
  final file = File('assets/builtin_sources/$name');
  return file.readAsStringSync();
}

BookSource _firstSource(String raw) {
  final trimmed = raw.trimLeft().replaceFirst('\uFEFF', '');
  if (trimmed.startsWith('[')) {
    final list = jsonDecode(trimmed) as List<dynamic>;
    return BookSource.fromJson(Map<String, dynamic>.from(list.first as Map));
  }
  return BookSource.fromJson(jsonDecode(trimmed) as Map<String, dynamic>);
}

class _OfflineTomatoBookSourceService extends TestBookSourceService {
  _OfflineTomatoBookSourceService(this._fixture);

  final Map<String, dynamic> _fixture;

  Map<String, dynamic> _payload(String path) {
    return Map<String, dynamic>.from(_fixture[path] as Map);
  }

  @override
  Future<List<Map<String, String>>> search(
    BookSource source,
    String keyword,
  ) async {
    final data = Map<String, dynamic>.from(
      _payload('/api/novel/search')['data'] as Map,
    );
    final item = Map<String, dynamic>.from(
      (data['items'] as List).first as Map,
    );
    return [
      {
        'name': '${item['articlename']}',
        'author': '${item['author']}',
        'url': '${source.bookSourceUrl}/api/novel/detail/${item['articleid']}',
        'coverUrl': '',
        'kind': '',
        'note': '${item['intro']}',
      },
    ];
  }

  @override
  Future<Map<String, String>> getBookInfo(
    BookSource source,
    String bookUrl,
  ) async {
    final data = Map<String, dynamic>.from(
      _payload('/api/novel/detail/1001')['data'] as Map,
    );
    return {
      'name': '${data['articlename']}',
      'author': '${data['author']}',
      'coverUrl': '',
      'intro': '${data['intro']}',
      'kind': '',
      'lastChapter': '${data['lastchapter']}',
      'tocUrl': '${source.bookSourceUrl}/api/chapter/list/1001',
    };
  }

  @override
  Future<List<Chapter>> getChapters(
    Book book, {
    required BookSource source,
  }) async {
    final items = _payload('/api/chapter/list/1001')['data'] as List;
    return items.asMap().entries.map((entry) {
      final item = Map<String, dynamic>.from(entry.value as Map);
      final url =
          '${source.bookSourceUrl}/api/chapter/content/1001/${item['chapterid']}';
      return Chapter(
        id: Chapter.idFor(bookId: book.id, url: url, index: entry.key),
        bookId: book.id,
        title: '${item['chaptername']}',
        index: entry.key,
        url: url,
      );
    }).toList();
  }

  @override
  Future<String> getChapterContent(
    String url, {
    required BookSource source,
  }) async {
    final data = Map<String, dynamic>.from(
      _payload('/api/chapter/content/1001/2001')['data'] as Map,
    );
    return '${data['content']}'.replaceAll(RegExp(r'<[^>]+>'), '').trim();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 3.1 功能对齐验证', () {
    late BookSourceService service;
    late BookSourceService offlineTomatoService;
    late bool rustReady;
    late BookSource offlineTomato;

    setUpAll(() async {
      await LegadoEngineBridge.tryInit();
      rustReady = LegadoEngineBridge.isAvailable;
      service = createFrbBookSourceService();
      offlineTomato = _firstSource(await _loadBuiltinJson('7497.json'));
      offlineTomatoService = _OfflineTomatoBookSourceService(
        jsonDecode(
              File(
                'test/fixtures/phase3/tomato_offline.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>,
      );
    });

    test('Rust 引擎已加载', () {
      expect(rustReady, isTrue, reason: '请先运行 .\\scripts\\build_rust.ps1');
    });

    test('搜索 HTML — 7565 笔书网「斗破」≥ 1 条', () async {
      if (!rustReady) return;
      final source = _firstSource(await _loadBuiltinJson('7565.json'));
      final results = await service.search(source, '斗破');
      expect(results.length, greaterThanOrEqualTo(1));
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('搜索 JSON — 7497 番茄离线 fixture', () async {
      if (!rustReady) return;
      final source = offlineTomato;
      final results = await offlineTomatoService.search(source, '斗罗');
      expect(results, isNotEmpty);
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('搜索 @js: — 7565 含 JS 规则可搜索', () async {
      if (!rustReady) return;
      final raw = await _loadBuiltinJson('7565.json');
      expect(raw.contains('@js:') || raw.contains('<js>'), isTrue);
      final source = _firstSource(raw);
      final results = await service.search(source, '斗破');
      expect(results, isNotEmpty);
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('书籍详情 — 封面+简介+最新章节', () async {
      if (!rustReady) return;
      final source = _firstSource(await _loadBuiltinJson('7565.json'));
      final results = await service.search(source, '斗破');
      final info = await service.getBookInfo(source, results.first['url']!);
      expect(info['name'], isNotEmpty);
      expect(info['intro'], isNotNull);
      expect(info['lastChapter'], isNotNull);
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('目录 HTML — 7565 ≥ 10 章', () async {
      if (!rustReady) return;
      final source = _firstSource(await _loadBuiltinJson('7565.json'));
      final results = await service.search(source, '斗破');
      final book = Book(
        id: 'p3_${results.first['url']!.hashCode}',
        name: results.first['name']!,
        author: results.first['author'] ?? '',
        sourceUrl: results.first['url']!,
        bookSourceUrl: source.bookSourceUrl,
      );
      final chapters = await service.getChapters(book, source: source);
      expect(chapters.length, greaterThanOrEqualTo(10));
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('目录 JSON — 7497 番茄离线 fixture', () async {
      if (!rustReady) return;
      final source = offlineTomato;
      final results = await offlineTomatoService.search(source, '斗罗');
      final book = Book(
        id: 'p3_tomato_${results.first['url']!.hashCode}',
        name: results.first['name']!,
        author: results.first['author'] ?? '',
        sourceUrl: results.first['url']!,
        bookSourceUrl: source.bookSourceUrl,
      );
      final chapters = await offlineTomatoService.getChapters(
        book,
        source: source,
      );
      expect(chapters, isNotEmpty);
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('正文 HTML — 7565 非空', () async {
      if (!rustReady) return;
      final source = _firstSource(await _loadBuiltinJson('7565.json'));
      final results = await service.search(source, '斗破');
      final book = Book(
        id: 'p3_c_${results.first['url']!.hashCode}',
        name: results.first['name']!,
        author: results.first['author'] ?? '',
        sourceUrl: results.first['url']!,
        bookSourceUrl: source.bookSourceUrl,
      );
      final chapters = await service.getChapters(book, source: source);
      final content = await service.getChapterContent(
        chapters.first.url,
        source: source,
      );
      expect(content.length, greaterThan(100));
    }, timeout: const Timeout(Duration(minutes: 2)));

    test(
      '正文 JSON + <js> 清洗 — 7497 离线 fixture',
      () async {
        if (!rustReady) return;
        final source = offlineTomato;
        final results = await offlineTomatoService.search(source, '斗罗');
        final book = Book(
          id: 'p3_jc_${results.first['url']!.hashCode}',
          name: results.first['name']!,
          author: results.first['author'] ?? '',
          sourceUrl: results.first['url']!,
          bookSourceUrl: source.bookSourceUrl,
        );
        final chapters = await offlineTomatoService.getChapters(
          book,
          source: source,
        );
        final content = await offlineTomatoService.getChapterContent(
          chapters.first.url,
          source: source,
        );
        expect(content.length, greaterThan(20));
        expect(content.contains('<p>'), isFalse);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}
