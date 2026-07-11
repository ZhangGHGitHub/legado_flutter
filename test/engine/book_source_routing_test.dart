import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/models/book_source.dart';
import 'package:legado_flutter/services/book_source_service.dart';

Future<String> _loadBuiltinJson(String name) async {
  final file = File('assets/builtin_sources/$name');
  if (file.existsSync()) {
    return file.readAsStringSync();
  }
  return rootBundle.loadString('assets/builtin_sources/$name');
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

  group('BookSourceService.needsDartEngine', () {
    test('7565 笔书网 HTML+JS 规则不走 Dart', () async {
      final source = _firstSource(await _loadBuiltinJson('7565.json'));
      expect(BookSourceService.needsDartEngine(source, operation: 'search'), isFalse);
      expect(BookSourceService.needsDartEngine(source, operation: 'toc'), isFalse);
      expect(BookSourceService.needsDartEngine(source, operation: 'content'), isFalse);
      expect(BookSourceService.needsDartEngine(source, operation: 'bookInfo'), isFalse);
    });

    test('7497 番茄 JSON+jsLib 不走 Dart', () async {
      final source = _firstSource(await _loadBuiltinJson('7497.json'));
      expect(BookSourceService.needsDartEngine(source, operation: 'search'), isFalse);
      expect(BookSourceService.needsDartEngine(source, operation: 'toc'), isFalse);
      expect(BookSourceService.needsDartEngine(source, operation: 'content'), isFalse);
      expect(BookSourceService.needsDartEngine(source, operation: 'bookInfo'), isFalse);
    });

    test('Rust 处理 @js: 搜索 URL，不强制 Dart', () {
      final source = BookSource.fromJson({
        'bookSourceUrl': 'http://x.com',
        'searchUrl': '@js:java.ajax(...)',
        'ruleChapterUrl': 'http://x.com/toc',
      });
      expect(BookSourceService.needsDartEngine(source, operation: 'search'), isFalse);
      expect(BookSourceService.needsDartEngine(source, operation: 'toc'), isFalse);
    });
  });
}
