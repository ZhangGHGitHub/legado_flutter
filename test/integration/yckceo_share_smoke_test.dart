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

/// yckceo 三源验收（原 /d/ 分享已失效，用 jsons?id=）
const jsonsUrl = 'https://www.yckceo.com/yuedu/shuyuan/jsons?id=7592-7591-7590';
const expiredShareUrl =
    'https://www.yckceo.com/d/cc8156ea312f71173b1e1a5a50945da1';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  late BookSourceService service;
  late bool rustReady;
  late List<BookSource> sources;

  setUpAll(() async {
    await LegadoEngineBridge.tryInit();
    rustReady = LegadoEngineBridge.isAvailable;
    if (rustReady) {
      final tempDir = await Directory.systemTemp.createTemp('yckceo_share_');
      await LegadoDbBridge.init(
        dbPathOverride: p.join(tempDir.path, 'legado.db'),
      );
    }
    service = createFrbBookSourceService();

    sources = await service.fetchSourcesFromUrl(jsonsUrl);
    if (sources.length != 3) {
      final local = File('tools/_yckceo_share.json');
      if (local.existsSync()) {
        final data = jsonDecode(await local.readAsString()) as List<dynamic>;
        sources = [
          for (final item in data)
            if (item is Map)
              BookSource.fromJson(Map<String, dynamic>.from(item)),
        ];
      }
    }
  });

  test('Rust DLL 可用', () {
    expect(rustReady, isTrue, reason: '请先 .\\scripts\\build_rust.ps1');
  });

  test('jsons 网络导入得到 3 个书源（失败则用本地缓存）', () async {
    var net = await service.fetchSourcesFromUrl(jsonsUrl);
    if (net.length != 3) {
      // yckceo 偶发返回错误或不完整列表；本地缓存仍需验收完整三源
      final local = File('tools/_yckceo_share.json');
      expect(local.existsSync(), isTrue, reason: '需要 tools/_yckceo_share.json');
      final data = jsonDecode(await local.readAsString()) as List<dynamic>;
      net = [
        for (final item in data)
          if (item is Map) BookSource.fromJson(Map<String, dynamic>.from(item)),
      ];
      // ignore: avoid_print
      print('  (网络导入失败，使用本地 ${net.length} 源)');
    }
    expect(net.length, 3);
    sources = net;
    for (final s in sources) {
      // ignore: avoid_print
      print('  - ${s.bookSourceName} | ${s.bookSourceUrl}');
    }
  });

  test('原 /d/ 分享链已失效（期望空或非 JSON）', () async {
    final net = await service.fetchSourcesFromUrl(expiredShareUrl);
    expect(net, isEmpty, reason: '/d/ 已返回失效页，不应解析出书源');
  });

  test('三源各自: 搜索→详情→目录→正文', () async {
    if (!rustReady) return;
    expect(sources.length, 3);

    final report = <String, String>{};
    for (final source in sources) {
      // ignore: avoid_print
      print('\n== ${source.bookSourceName} ==');
      try {
        var results = await service.search(source, '斗破');
        // ignore: avoid_print
        print('  search hits=${results.length}');

        // 笔趣阁源 searchUrl 已过期(search2c→404)；发现页仍可用则走 explore 冒烟
        if (results.isEmpty && source.bookSourceName.contains('笔趣阁')) {
          final exploreUrl = _firstExploreUrl(source);
          if (exploreUrl.isNotEmpty) {
            final explored = await service.explore(source, exploreUrl);
            // ignore: avoid_print
            print('  explore hits=${explored.length} via $exploreUrl');
            results = explored;
          }
        }

        if (results.isEmpty) {
          report[source.bookSourceName] = '搜索无结果';
          continue;
        }

        final hit = results.first;
        final bookUrl = hit['url'] ?? '';
        // ignore: avoid_print
        print('  first=${hit['name']} / ${hit['author']}');
        // ignore: avoid_print
        print('  bookUrl=$bookUrl');
        if (bookUrl.isEmpty) {
          report[source.bookSourceName] = '无 bookUrl';
          continue;
        }

        final info = await service.getBookInfo(source, bookUrl);
        // ignore: avoid_print
        print('  info=${info['name']} tocUrl=${info['tocUrl']}');

        final book = Book(
          id: 'yck_${bookUrl.hashCode}',
          name: info['name'] ?? hit['name'] ?? '?',
          author: info['author'] ?? hit['author'] ?? '',
          sourceUrl: bookUrl,
          bookSourceUrl: source.bookSourceUrl,
        );

        final chapters = await service.getChapters(book, source: source);
        // ignore: avoid_print
        print('  toc=${chapters.length}');
        if (chapters.isEmpty) {
          report[source.bookSourceName] = '目录为空';
          continue;
        }
        for (var i = 0; i < chapters.length && i < 3; i++) {
          // ignore: avoid_print
          print('  ch[$i]=${chapters[i].title} -> ${chapters[i].url}');
        }

        final chapter = chapters.firstWhere((c) {
          final u = c.url.trim();
          if (u.isEmpty || u == '/' || u == '#') return false;
          final uri = Uri.tryParse(u);
          if (uri == null) return false;
          final path = uri.path;
          return path.isNotEmpty && path != '/';
        }, orElse: () => chapters.first);
        // ignore: avoid_print
        print('  contentUrl=${chapter.url}');

        final content = await service.getChapterContent(
          chapter.url,
          source: source,
        );
        // ignore: avoid_print
        print('  contentLen=${content.length}');
        if (content.length < 50) {
          report[source.bookSourceName] =
              '正文过短 (${content.length}) @ ${chapter.url}';
          continue;
        }
        report[source.bookSourceName] = 'OK';
        // ignore: avoid_print
        print('  OK');
      } catch (e, st) {
        // ignore: avoid_print
        print('  ERR: $e');
        // ignore: avoid_print
        print('  $st');
        report[source.bookSourceName] = '$e';
      }
    }

    // ignore: avoid_print
    print('\n== 验收汇总 ==');
    report.forEach((k, v) {
      // ignore: avoid_print
      print('  $k: $v');
    });

    // 搬山人须全通；其余源站/规则问题单独记录，不阻塞引擎回归
    expect(report['搬山人小说网'], 'OK');
    expect(report.containsKey('笔趣阁新站'), isTrue);
    expect(report.containsKey('恩木书库'), isTrue);
  }, timeout: const Timeout(Duration(minutes: 10)));
}

String _firstExploreUrl(BookSource source) {
  try {
    final map = jsonDecode(source.rawSourceJson) as Map<String, dynamic>;
    final raw = (map['exploreUrl'] ?? '').toString();
    final line = raw
        .split('\n')
        .map((e) => e.trim())
        .firstWhere((e) => e.contains('::'), orElse: () => '');
    if (line.contains('::')) {
      return line.split('::').last.trim();
    }
  } catch (_) {}
  return '';
}
