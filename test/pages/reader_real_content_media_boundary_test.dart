import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/features/reader/reader_markup.dart';
import 'package:legado_flutter/features/reader/reader_paginator.dart';

Map<String, dynamic> _readFixture() {
  return jsonDecode(
        File(
          'test/fixtures/reader/module3/real_content/'
          'real_content_media_boundary_001.json',
        ).readAsStringSync(),
      )
      as Map<String, dynamic>;
}

void main() {
  test('real media markup preserves visible order and source ranges', () {
    final fixture = _readFixture();
    final document = ReaderMarkup.parse(fixture['raw'] as String);

    expect(document.plainText, fixture['expectedPlainText']);
    expect(document.images, hasLength(2));
    expect(
      document.images.map((image) => image.source).toList(),
      fixture['expectedImageSources'],
    );
    expect(
      document.images.map(
        (image) => document.plainText.substring(image.start, image.end),
      ),
      everyElement(ReaderMarkup.imagePlaceholder),
    );

    final audioStart = document.plainText.indexOf('音频备用');
    expect(audioStart, greaterThan(document.images.first.end));
    expect(document.plainText, isNot(contains('<audio')));
    expect(document.plainText, isNot(contains('clip.mp3')));
    expect(
      document.plainText.indexOf('结尾'),
      greaterThanOrEqualTo(audioStart + '音频备用'.length),
    );
    expect(document.images.last.start, greaterThan(audioStart));
  });

  test('hard page marker separates media content from chapter tail', () {
    final fixture = _readFixture();
    final document = ReaderMarkup.parse(fixture['raw'] as String);
    final marker = RegExp(r'\[newpage\]').firstMatch(document.plainText)!;
    final markerLine = RegExp(r'\[newpage\]\n')
        .allMatches(document.plainText)
        .firstWhere((match) => match.start == marker.start);

    final pages = ReaderPaginator.paginate(
      text: document.plainText,
      style: const TextStyle(fontSize: 16, height: 1.2),
      maxWidth: 360,
      maxHeight: 1000,
      respectHardPageBreaks: true,
    );

    expect(pages, hasLength(2));
    expect(pages.first.start, 0);
    expect(pages.first.end, marker.start);
    expect(pages.last.start, markerLine.end);
    expect(pages.last.end, document.plainText.length);
    expect(
      pages.map((page) => page.text).join(),
      fixture['expectedVisibleAfterHardBreak'],
    );
    expect(pages.every((page) => !page.text.contains('[newpage]')), isTrue);
    expect(
      document.plainText.substring(pages.first.end, pages.last.start),
      '[newpage]\n',
    );
  });
}
