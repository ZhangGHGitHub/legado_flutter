import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/services/js_compat_analyzer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JsCompatAnalyzer', () {
    test('7565 笔书网 detects jsoup search/explore/content', () async {
      final raw = await rootBundle.loadString('assets/builtin_sources/7565.json');
      final report = JsCompatAnalyzer.scanJson(raw);

      expect(report.sourceName, '笔书网手机版');
      expect(report.hasJsRules, isTrue);
      expect(report.usesJsoup, isTrue);
      expect(report.jsBlockCount, 3);
      expect(report.jsFields, contains('ruleSearch'));
      expect(report.jsFields, contains('ruleExplore'));
      expect(report.jsFields, contains('ruleContent'));
    });

    test('7497 番茄 detects jsLib and content js blocks', () async {
      final raw = await rootBundle.loadString('assets/builtin_sources/7497.json');
      final report = JsCompatAnalyzer.scanJson(raw);

      expect(report.sourceName, contains('番茄'));
      expect(report.hasJsLib, isTrue);
      expect(report.jsBlockCount, greaterThanOrEqualTo(6));
      expect(report.jsFields, contains('jsLib'));
      expect(report.jsFields, contains('ruleContent'));
    });

    test('counts ASCII case variants of @js: and classifies their fields', () {
      const raw = '''
{
  "bookSourceName": "mixed-case fixture",
  "bookSourceUrl": "https://example.com",
  "searchUrl": "@JS:search",
  "ruleSearch": {"bookList": "@Js:search-list"},
  "ruleContent": {"content": "@jS:content <Js>value</jS>"}
}
''';

      final report = JsCompatAnalyzer.scanJson(raw);

      expect(report.atJsCount, 3);
      expect(report.jsBlockCount, 1);
      expect(report.jsFields, containsAll(<String>[
        'searchUrl',
        'ruleSearch',
        'ruleContent',
      ]));
    });
  });
}
