import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/pages/code_edit/code_edit_formatter.dart';
import 'package:legado_flutter/pages/code_edit/code_edit_highlighter.dart';
import 'package:legado_flutter/pages/code_edit/code_edit_theme.dart';
import 'package:flutter/material.dart';

void main() {
  test('formats JSON with 4-space indent like js_beautify', () {
    final out = CodeEditFormatter.format('{"a":1,"b":[2]}');
    expect(out, contains('    "a"'));
    expect(out, contains('    "b"'));
  });

  test('formats @js: segment', () {
    final out = CodeEditFormatter.format('@js:function(){return 1}');
    expect(out.startsWith('@js:'), isTrue);
    expect(out, contains('function'));
  });

  test('formats <js> segment', () {
    final out = CodeEditFormatter.format('prefix<js>var a=1</js>suffix');
    expect(out, contains('<js>'));
    expect(out, contains('</js>'));
  });

  test('skips markdown', () {
    expect(
      () => CodeEditFormatter.format('# hi', languageName: 'markdown'),
      throwsA(isA<FormatSkipException>()),
    );
  });

  test('Monokai palette matches Jingshiro token colors', () {
    final p = CodeEditPalette.byIndex(1);
    expect(p.name, 'Monokai');
    expect(p.background, const Color(0xFF272822));
    expect(p.string, const Color(0xFFE6DB74));
    expect(p.keyword, const Color(0xFFF92672));
    expect(p.number, const Color(0xFFAE81FF));
  });

  test('highlighter emits spans for JSON keys and strings', () {
    final p = CodeEditPalette.byIndex(1);
    final base = TextStyle(color: p.foreground, fontFamily: 'monospace');
    final spans = highlightJsJson('{"a":"x", "n":1}', p, base);
    expect(spans, isNotEmpty);
    final texts = spans.map((s) => (s as TextSpan).text ?? '').join();
    expect(texts, '{"a":"x", "n":1}');
  });
}
