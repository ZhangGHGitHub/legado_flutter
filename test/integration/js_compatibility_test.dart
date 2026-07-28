import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/services/js_compat_analyzer.dart';

/// 内置书源 JS 规则扫描和可选在线探测（REFACTOR_PLAN #2）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('js compatibility', () {
    test('builtin sources js rule inventory', () async {
      final paths = [
        'assets/builtin_sources/7565.json',
        'assets/builtin_sources/7497.json',
      ];
      final reports = <JsCompatReport>[];
      for (final path in paths) {
        final raw = await rootBundle.loadString(path);
        reports.add(JsCompatAnalyzer.scanJson(raw));
      }

      expect(reports.every((r) => r.hasJsRules), isTrue);
      for (final r in reports) {
        // ignore: avoid_print
        print(r);
      }
    });

    test('7565 search endpoint reachable (optional online)', () async {
      final raw = await rootBundle.loadString(
        'assets/builtin_sources/7565.json',
      );
      final report = JsCompatAnalyzer.scanJson(raw);
      expect(report.usesJsoup, isTrue);

      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 8);
        final req = await client
            .getUrl(Uri.parse('https://m.biqukun.org/search.php?q=斗破苍穹'))
            .timeout(const Duration(seconds: 10));
        req.headers.set('User-Agent', 'Mozilla/5.0 LegadoFlutter/js-compat');
        final resp = await req.close().timeout(const Duration(seconds: 15));
        if (resp.statusCode != 200) {
          // ignore: avoid_print
          print('skip online 7565: HTTP ${resp.statusCode}');
          return;
        }
        await resp.drain<void>();
        // ignore: avoid_print
        print(
          'online 7565 search reachable (full pipeline in Rust e2e_builtin)',
        );
      } catch (e) {
        // ignore: avoid_print
        print('skip online 7565: $e');
      }
    });
  });
}
