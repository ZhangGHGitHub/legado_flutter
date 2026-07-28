import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/help/content_processor.dart';
import 'package:legado_flutter/features/reader/reader_markup.dart';
import 'package:legado_flutter/features/reader/reader_paginator.dart';

void main() {
  final fixture =
      jsonDecode(
            File(
              'test/fixtures/reader/module3/real_content/source_page.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;

  test(
    'real source content survives processing, markup parsing and paging',
    () {
      final processed = ContentProcessor.instance.processForReading(
        fixture['raw'] as String,
        chapterTitle: fixture['chapterTitle'] as String,
        paragraphIndent: fixture['paragraphIndent'] as String,
        reSegment: false,
        useReplace: false,
      );
      expect(processed, fixture['expectedProcessed']);

      final document = ReaderMarkup.parse(processed);
      expect(document.plainText, fixture['expectedPlainText']);
      expect(document.images, hasLength(1));
      expect(document.images.single.source, 'cover.jpg');
      expect(document.images.single.style, 'FULL');
      expect(document.plainText, isNot(contains('<usehtml>')));
      expect(document.plainText, contains(ReaderMarkup.imagePlaceholder));

      final pages = ReaderPaginator.paginate(
        text: document.plainText,
        style: const TextStyle(fontSize: 16, height: 1.2),
        maxWidth: 360,
        maxHeight: 1000,
        respectHardPageBreaks: true,
      );
      expect(pages, hasLength(2));
      expect(pages.first.text, contains('第二段'));
      expect(pages.first.text, isNot(contains('[newpage]')));
      expect(pages.last.text, contains('第三段'));
    },
  );
}
