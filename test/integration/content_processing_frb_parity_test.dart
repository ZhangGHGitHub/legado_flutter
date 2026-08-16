import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/bridge/legado_engine_bridge.dart';
import 'package:legado_flutter/domain/content/replace_rule.dart';
import 'package:legado_flutter/domain/ports/content_processing_port.dart';
import 'package:legado_flutter/help/content_processor.dart';
import 'package:legado_flutter/infrastructure/content/frb_content_processing_port.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await LegadoEngineBridge.tryInit();
    expect(
      LegadoEngineBridge.isAvailable,
      isTrue,
      reason: '请先构建当前 Rust 动态库，不能用 Dart fallback 代替 FRB 双跑',
    );
  });

  test('real module 3 fixture matches between Dart and Rust', () {
    final fixture =
        jsonDecode(
              File(
                'test/fixtures/reader/module3/real_content/real_content_pipeline_001.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final rules = (fixture['replaceRules'] as List<dynamic>)
        .map((rule) => ReplaceRule.fromJson(rule as Map<String, dynamic>))
        .toList(growable: false);
    final sourceJson = fixture['sourceRules'] as Map<String, dynamic>;
    final sourceRules = ContentProcessingSourceRules(
      contentReplace: sourceJson['contentReplace'] as String,
      contentReplaceTo: sourceJson['contentReplaceTo'] as String,
    );

    final dart = ContentProcessor.instance..loadRules(rules);
    final rust = FrbContentProcessingPort()..loadRules(rules);

    final dartResult = dart.processForReading(
      fixture['raw'] as String,
      chapterTitle: fixture['chapterTitle'] as String,
      bookName: fixture['bookName'] as String,
      includeTitle: fixture['includeTitle'] as bool,
      useReplace: fixture['useReplace'] as bool,
      paragraphIndent: fixture['paragraphIndent'] as String,
      reSegment: fixture['reSegment'] as bool,
      sourceRules: BookSourceRules(
        contentReplace: sourceRules.contentReplace,
        contentReplaceTo: sourceRules.contentReplaceTo,
      ),
    );
    final rustResult = rust.processForReading(
      fixture['raw'] as String,
      chapterTitle: fixture['chapterTitle'] as String,
      bookName: fixture['bookName'] as String,
      includeTitle: fixture['includeTitle'] as bool,
      useReplace: fixture['useReplace'] as bool,
      paragraphIndent: fixture['paragraphIndent'] as String,
      reSegment: fixture['reSegment'] as bool,
      sourceRules: sourceRules,
    );

    expect(rustResult, dartResult);
    expect(rustResult, fixture['expectedProcessed']);
  });

  test('global and source replacement order matches Dart', () {
    final rules = [
      ReplaceRule(
        id: 'literal',
        name: 'literal',
        pattern: 'PLACEHOLDER',
        replacement: '追踪参数=42',
        isRegex: false,
      ),
    ];
    final dart = ContentProcessor.instance..loadRules(rules);
    final rust = FrbContentProcessingPort()..loadRules(rules);

    final dartResult = dart.process(
      'PLACEHOLDER',
      sourceRules: const BookSourceRules(
        contentReplace: r'追踪参数=\d+',
        contentReplaceTo: '追踪参数=N',
      ),
    );
    final rustResult = rust.process(
      'PLACEHOLDER',
      sourceRules: const ContentProcessingSourceRules(
        contentReplace: r'追踪参数=\d+',
        contentReplaceTo: '追踪参数=N',
      ),
    );

    expect(rustResult, dartResult);
    expect(rustResult, '追踪参数=N');
  });

  test('stable reSegment fixture matches between Dart and Rust', () {
    final dart = ContentProcessor.instance..loadRules(const <ReplaceRule>[]);
    final rust = FrbContentProcessingPort()..loadRules(const <ReplaceRule>[]);

    final dartResult = dart.processForReading(
      '他说。',
      includeTitle: false,
      useReplace: false,
      reSegment: true,
    );
    final rustResult = rust.processForReading(
      '他说。',
      includeTitle: false,
      useReplace: false,
      reSegment: true,
    );

    expect(rustResult, dartResult);
    expect(rustResult, '他说。');
  });
}
