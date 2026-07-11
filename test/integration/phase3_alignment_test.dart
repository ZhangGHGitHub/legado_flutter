import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/bridge/legado_engine_bridge.dart';
import 'package:legado_flutter/models/book.dart';
import 'package:legado_flutter/models/book_source.dart';
import 'package:legado_flutter/services/book_source_service.dart';

/// Phase 3.1 功能对齐验证（需 Rust DLL + 网络）
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 3.1 功能对齐验证', () {
    late BookSourceService service;
    late bool rustReady;

    setUpAll(() async {
      await LegadoEngineBridge.tryInit();
      rustReady = LegadoEngineBridge.isAvailable;
      service = BookSourceService();
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

    test('搜索 JSON — 7497 番茄', () async {
      if (!rustReady) return;
      final source = _firstSource(await _loadBuiltinJson('7497.json'));
      final results = await service.search(source, '斗罗');
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

    test('目录 JSON — 7497 番茄', () async {
      if (!rustReady) return;
      final source = _firstSource(await _loadBuiltinJson('7497.json'));
      final results = await service.search(source, '斗罗');
      final book = Book(
        id: 'p3_tomato_${results.first['url']!.hashCode}',
        name: results.first['name']!,
        author: results.first['author'] ?? '',
        sourceUrl: results.first['url']!,
        bookSourceUrl: source.bookSourceUrl,
      );
      final chapters = await service.getChapters(book, source: source);
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

    test('正文 JSON + <js> 清洗 — 7497', () async {
      if (!rustReady) return;
      final source = _firstSource(await _loadBuiltinJson('7497.json'));
      final results = await service.search(source, '斗罗');
      final book = Book(
        id: 'p3_jc_${results.first['url']!.hashCode}',
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
      expect(content.length, greaterThan(20));
      expect(content.contains('<p>'), isFalse);
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
