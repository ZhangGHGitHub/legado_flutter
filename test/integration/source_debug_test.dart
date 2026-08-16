import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/bridge/legado_engine_bridge.dart';
import 'package:legado_flutter/domain/source/book_source.dart';

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

  group('书源调试器 Rust 集成', () {
    late bool rustReady;

    setUpAll(() async {
      await LegadoEngineBridge.tryInit();
      rustReady = LegadoEngineBridge.isAvailable;
    });

    test('7565 笔书网 debug_search 分步结果', () async {
      if (!rustReady) return;

      final source = _firstSource(await _loadBuiltinJson('7565.json'));
      final result = await LegadoEngineBridge.debugSearch(source, '斗破');

      expect(result.requestUrl, isNotEmpty);
      expect(result.responseStatus, '200');
      expect(result.ruleSteps, isNotEmpty);
      expect(result.results, isNotEmpty);
      expect(
        result.ruleSteps.any((s) => s.step.contains('HTTP')),
        isTrue,
      );
    });
  });
}
