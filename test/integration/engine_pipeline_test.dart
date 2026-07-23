import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:legado_flutter/bridge/legado_db_bridge.dart';
import 'package:legado_flutter/bridge/legado_engine_bridge.dart';
import 'package:legado_flutter/database/database_helper.dart';
import 'package:legado_flutter/models/book.dart';
import 'package:legado_flutter/models/book_source.dart';
import 'package:legado_flutter/services/book_source_service.dart';

import '../helpers/online_smoke_gate.dart';

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

  group('Rust 引擎集成验证', () {
    late BookSourceService service;
    late bool rustReady;

    setUpAll(() async {
      await LegadoEngineBridge.tryInit();
      rustReady = LegadoEngineBridge.isAvailable;
      if (rustReady) {
        final tempDir = await Directory.systemTemp.createTemp('legado_test_');
        await LegadoDbBridge.init(
          dbPathOverride: p.join(tempDir.path, 'legado.db'),
        );
      }
      service = BookSourceService();
    });

    test('Rust DLL 已加载', () {
      expect(rustReady, isTrue, reason: '请先运行 .\\scripts\\build_rust.ps1');
    });

    test('7565 笔书网: 搜索→详情→目录→正文', () async {
      if (!rustReady) return;

      final source = _firstSource(await _loadBuiltinJson('7565.json'));
      final results = await service.search(source, '斗破');
      expect(results, isNotEmpty, reason: '搜索无结果');

      final bookUrl = results.first['url']!;
      final info = await service.getBookInfo(source, bookUrl);
      expect(info['name'], isNotEmpty);

      final book = Book(
        id: 'test_${bookUrl.hashCode}',
        name: info['name'] ?? results.first['name']!,
        author: info['author'] ?? results.first['author'] ?? '',
        sourceUrl: bookUrl,
        bookSourceUrl: source.bookSourceUrl,
      );

      final chapters = await service.getChapters(book, source: source);
      expect(chapters.length, greaterThan(10), reason: '目录过短');

      final content = await service.getChapterContent(
        chapters.first.url,
        source: source,
      );
      expect(
        content.length,
        greaterThan(500),
        reason: '正文过短: ${content.length}',
      );

      // DB 往返
      await DatabaseHelper().insertBook(book);
      await DatabaseHelper().insertChapters(chapters);
      final dbBooks = await DatabaseHelper().getBooks();
      expect(dbBooks.any((b) => b.id == book.id), isTrue);
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('书源开关: rawSourceJson 与 enabled 列同步', () async {
      if (!rustReady) return;

      final db = DatabaseHelper();
      final source7565 = _firstSource(await _loadBuiltinJson('7565.json'));
      final source7497 = _firstSource(await _loadBuiltinJson('7497.json'));
      await db.insertBookSources([source7565, source7497]);

      await db.toggleSource(source7565.bookSourceUrl, false);
      final enabled = await db.getEnabledSources();
      expect(
        enabled.any((s) => s.bookSourceUrl == source7565.bookSourceUrl),
        isFalse,
      );
      expect(
        enabled.any((s) => s.bookSourceUrl == source7497.bookSourceUrl),
        isTrue,
      );

      final all = await db.getBookSources();
      final disabled = all.firstWhere(
        (s) => s.bookSourceUrl == source7565.bookSourceUrl,
      );
      expect(disabled.enabled, isFalse);

      await db.toggleSource(source7565.bookSourceUrl, true);
    });

    test(
      '7497 番茄: 搜索→目录→正文',
      () async {
        if (!rustReady) return;

        final source = _firstSource(await _loadBuiltinJson('7497.json'));
        final results = await service.search(source, '斗罗');
        expect(results, isNotEmpty);

        final bookUrl = results.first['url']!;
        final book = Book(
          id: 'test_tomato_${bookUrl.hashCode}',
          name: results.first['name']!,
          author: results.first['author'] ?? '',
          sourceUrl: bookUrl,
          bookSourceUrl: source.bookSourceUrl,
        );

        final chapters = await service.getChapters(book, source: source);
        expect(chapters, isNotEmpty);

        final content = await service.getChapterContent(
          chapters.first.url,
          source: source,
        );
        expect(content.length, greaterThan(20));
        expect(content.contains('<p>'), isFalse);
      },
      timeout: const Timeout(Duration(minutes: 2)),
      skip: onlineSmokeSkipReason,
    );
  });
}
