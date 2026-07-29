import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:legado_flutter/bridge/legado_db_bridge.dart';
import 'package:legado_flutter/bridge/legado_engine_bridge.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/models/book_source.dart';
import 'package:legado_flutter/services/book_source_service.dart';
import '../helpers/book_source_service_test_factory.dart';

import '../helpers/online_smoke_gate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  late BookSourceService service;
  late BookSource source;

  setUpAll(() async {
    await LegadoEngineBridge.tryInit();
    expect(LegadoEngineBridge.isAvailable, isTrue);
    final tempDir = await Directory.systemTemp.createTemp('src7497_');
    await LegadoDbBridge.init(
      dbPathOverride: p.join(tempDir.path, 'legado.db'),
    );
    service = createFrbBookSourceService();

    final file = File('tools/_src_7497.json').existsSync()
        ? File('tools/_src_7497.json')
        : File('assets/builtin_sources/7497.json');
    final data = jsonDecode(await file.readAsString());
    final item = (data is List ? data.first : data) as Map;
    source = BookSource.fromJson(Map<String, dynamic>.from(item));
    // ignore: avoid_print
    print('source=${source.bookSourceName} | ${source.bookSourceUrl}');
  });

  test(
    '7497 校验应通过',
    () async {
      final v = await LegadoEngineBridge.validateSource(source, keyword: '斗破');
      // ignore: avoid_print
      print(
        'validate search=${v.searchOk} explore=${v.discoveryOk} '
        'toc=${v.tocOk} content=${v.contentOk} errors=${v.errors}',
      );
      expect(v.searchOk, isTrue, reason: '${v.errors}');
      expect(v.tocOk, isTrue, reason: '${v.errors}');
      expect(v.contentOk, isTrue, reason: '${v.errors}');
    },
    timeout: const Timeout(Duration(minutes: 5)),
    skip: onlineSmokeSkipReason,
  );

  test(
    '7497 搜索→详情→目录→正文',
    () async {
      final results = await service.search(source, '斗破');
      // ignore: avoid_print
      print('search hits=${results.length}');
      expect(results, isNotEmpty);

      final hit = results.first;
      final bookUrl = hit['url'] ?? '';
      // ignore: avoid_print
      print('first=${hit['name']} bookUrl=$bookUrl');

      final info = await service.getBookInfo(source, bookUrl);
      // ignore: avoid_print
      print('info=${info['name']} tocUrl=${info['tocUrl']}');
      expect(info['tocUrl'] ?? '', contains('/api/chapter/list/'));

      final book = Book(
        id: 't7497',
        name: info['name'] ?? hit['name'] ?? '?',
        author: info['author'] ?? '',
        sourceUrl: bookUrl,
        bookSourceUrl: source.bookSourceUrl,
      );

      final chapters = await service.getChapters(book, source: source);
      // ignore: avoid_print
      print('toc=${chapters.length}');
      expect(chapters.length, greaterThan(5));
      // ignore: avoid_print
      print('ch0=${chapters.first.title} -> ${chapters.first.url}');

      final content = await service.getChapterContent(
        chapters.first.url,
        source: source,
      );
      // ignore: avoid_print
      print('contentLen=${content.length}');
      expect(content.length, greaterThan(50));
    },
    timeout: const Timeout(Duration(minutes: 5)),
    skip: onlineSmokeSkipReason,
  );
}
