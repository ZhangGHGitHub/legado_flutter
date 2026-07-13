import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/models/book_source.dart';

void main() {
  test('fromJson preserves nested ruleContent for engine JSON', () {
    final legado = {
      'bookSourceUrl': 'https://novel.cooks.tw',
      'bookSourceName': '番茄',
      'header':
          '{"User-Agent":"UA-TEST","Referer":"https://novel.cooks.tw/"}',
      'jsLib': 'function Clean(r){return r}',
      'ruleContent': {'content': r'$.data.content'},
      'ruleToc': {
        'chapterList': r'$.data.list',
        'chapterName': r'$.title',
        'chapterUrl': r'$.url',
      },
    };

    final source = BookSource.fromJson(legado);
    final engine = jsonDecode(source.toEngineJson()) as Map<String, dynamic>;

    expect(engine['ruleContent'], isA<Map>());
    expect((engine['ruleContent'] as Map)['content'], r'$.data.content');
    expect(engine['ruleToc'], isA<Map>());
    expect(source.customHeaders['User-Agent'], 'UA-TEST');
  });

  test('toJson roundtrip does not flatten nested rules', () {
    final legado = {
      'bookSourceUrl': 'https://novel.cooks.tw',
      'bookSourceName': '番茄',
      'ruleContent': {'content': r'$.data.content'},
      'ruleToc': {'chapterList': r'$.data.list'},
    };
    final a = BookSource.fromJson(legado);
    final b = BookSource.fromJson(a.toJson());
    final engine = jsonDecode(b.toEngineJson()) as Map<String, dynamic>;
    expect(engine['ruleContent'], isA<Map>());
    expect((engine['ruleContent'] as Map)['content'], r'$.data.content');
  });

  test('embedded rawSourceJson recovered when outer ruleContent is flat', () {
    final nested = jsonEncode({
      'bookSourceUrl': 'https://novel.cooks.tw',
      'ruleContent': {'content': r'$.data.content'},
      'ruleToc': {'chapterList': r'$.x'},
    });
    final wrapper = {
      'bookSourceUrl': 'https://novel.cooks.tw',
      'bookSourceName': '番茄',
      'ruleContent': r'$.data.content',
      'rawSourceJson': nested,
    };
    final source = BookSource.fromJson(wrapper);
    final engine = jsonDecode(source.toEngineJson()) as Map<String, dynamic>;
    expect(engine['ruleContent'], isA<Map>());
  });
}
