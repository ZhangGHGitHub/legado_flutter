import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/help/content_processor.dart';
import 'package:legado_flutter/domain/content/replace_rule.dart';
import 'package:legado_flutter/features/reader/reader_markup.dart';
import 'package:legado_flutter/features/reader/reader_paginator.dart';

Map<String, dynamic> _readFixture(String name) {
  return jsonDecode(
        File(
          'test/fixtures/reader/module3/real_content/$name',
        ).readAsStringSync(),
      )
      as Map<String, dynamic>;
}

void main() {
  test('applies the replacement rule from the existing real fixture', () {
    final fixture = _readFixture('content_processor_real_source_001.json');
    final ruleJson = fixture['replaceRule'] as Map<String, dynamic>;
    ContentProcessor.instance.loadRules([
      ReplaceRule.fromJson({
        'id': 'content-processor-real-source-001',
        'name': 'content-processor-real-source-001',
        ...ruleJson,
      }),
    ]);

    final result = ContentProcessor.instance.processForReading(
      fixture['raw'] as String,
      chapterTitle: fixture['chapterTitle'] as String,
      paragraphIndent: fixture['paragraphIndent'] as String,
      includeTitle: false,
      useReplace: true,
      reSegment: false,
    );

    expect(result, fixture['expected']);
  });

  test('runs the real content preprocessing and reader pipeline in order', () {
    final fixture = _readFixture('real_content_pipeline_001.json');
    final rules = (fixture['replaceRules'] as List<dynamic>)
        .map((rule) => ReplaceRule.fromJson(rule as Map<String, dynamic>))
        .toList();
    ContentProcessor.instance.loadRules(rules);

    final processed = ContentProcessor.instance.processForReading(
      fixture['raw'] as String,
      chapterTitle: fixture['chapterTitle'] as String,
      bookName: fixture['bookName'] as String,
      includeTitle: fixture['includeTitle'] as bool,
      useReplace: fixture['useReplace'] as bool,
      paragraphIndent: fixture['paragraphIndent'] as String,
      reSegment: fixture['reSegment'] as bool,
      sourceRules: BookSourceRules(
        contentReplace:
            (fixture['sourceRules'] as Map<String, dynamic>)['contentReplace']
                as String,
        contentReplaceTo:
            (fixture['sourceRules'] as Map<String, dynamic>)['contentReplaceTo']
                as String,
      ),
    );
    expect(processed, fixture['expectedProcessed']);
    expect(processed, contains('净化后'));
    expect(processed, isNot(contains('PLACEHOLDER')));
    expect(processed, contains('https://example.com/read?id=42&lang=zh'));

    final document = ReaderMarkup.parse(processed);
    expect(document.plainText, fixture['expectedPlainText']);
    expect(document.images, hasLength(1));
    final image = document.images.single;
    expect(image.source, 'https://img.example.com/cover.png');
    expect(image.style, 'FULL');
    expect(image.width, '50%');
    expect(image.click, 'https://example.com/open?id=42');
    expect(document.plainText, isNot(contains('<usehtml>')));
    expect(document.plainText, contains(ReaderMarkup.imagePlaceholder));
    expect(
      document.runs.any(
        (run) =>
            run.text.contains('图文段') &&
            run.style?.fontWeight == FontWeight.bold,
      ),
      isTrue,
    );
    expect(
      document.runs.any(
        (run) =>
            run.text.contains('中文 English 123') &&
            run.style?.color == const Color(0xffff0000),
      ),
      isTrue,
    );

    final pages = ReaderPaginator.paginate(
      text: document.plainText,
      style: const TextStyle(fontSize: 16, height: 1.2),
      maxWidth: 360,
      maxHeight: 1000,
      respectHardPageBreaks: true,
    );
    expect(pages, hasLength(2));
    expect(pages.first.text, contains('中文与English混排'));
    expect(pages.first.text, contains(ReaderMarkup.imagePlaceholder));
    expect(pages.first.text, isNot(contains('[newpage]')));
    expect(pages.last.text, contains('末段中文 English 456'));
    expect(
      pages.map((page) => page.text).join(),
      fixture['expectedPlainTextWithoutNewPage'],
    );
    expect(pages.first.start, 0);
    expect(pages.last.end, document.plainText.length);
  });
}
