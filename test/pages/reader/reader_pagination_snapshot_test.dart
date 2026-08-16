import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/features/reader/reader_pagination_snapshot.dart';
import 'package:legado_flutter/features/reader/reader_paginator.dart';

void main() {
  testWidgets('snapshot contract preserves fixed geometry and page ranges', (
    tester,
  ) async {
    const source = '第一段\n[newpage]\n第二段\n第三段';
    const config = ReaderPaginationSnapshotConfig(
      fontFamily: 'NotoSansCJK-Regular',
      fontSize: 16,
      fontWeight: 400,
      devicePixelRatio: 2,
      viewportWidth: 360,
      viewportHeight: 640,
      contentLeft: 16,
      contentTop: 24,
      contentWidth: 328,
      contentHeight: 560,
      lineHeight: 1.5,
      renderedLineHeight: 28.125,
      letterSpacing: 0,
      paragraphSpacingTenths: 0,
      pageMode: 'horizontal',
    );
    final pages = ReaderPaginator.paginate(
      text: source,
      style: const TextStyle(fontSize: 16, height: 1.5),
      maxWidth: config.contentWidth,
      maxHeight: config.contentHeight,
    );
    final snapshot = ReaderPaginationSnapshot.fromSlices(
      fixtureId: 'module3-chapter-boundary-001',
      sourceText: source,
      chapterIndex: 2,
      chapterCount: 5,
      chapterStart: 0,
      chapterEnd: source.length,
      config: config,
      pages: pages,
    );

    expect(snapshot.validate(source), isEmpty);
    final json = jsonDecode(snapshot.encode()) as Map<String, dynamic>;
    final decoded = ReaderPaginationSnapshot.fromJson(json);
    expect(decoded.fixtureId, snapshot.fixtureId);
    expect(decoded.config.toJson(), config.toJson());
    expect(
      decoded.pages.map((page) => page.toJson()).toList(),
      snapshot.pages.map((page) => page.toJson()).toList(),
    );
    expect(json['schemaVersion'], ReaderPaginationSnapshot.schemaVersion);
    expect(
      (json['config'] as Map<String, dynamic>)['viewport'],
      containsPair('physicalWidth', 720.0),
    );
  });

  test(
    'snapshot validation rejects a range that skips ordinary source text',
    () {
      const source = '甲乙丙丁';
      const snapshot = ReaderPaginationSnapshot(
        fixtureId: 'invalid',
        sourceTextLength: source.length,
        chapterIndex: 0,
        chapterCount: 1,
        chapterStart: 0,
        chapterEnd: source.length,
        config: ReaderPaginationSnapshotConfig(
          fontFamily: 'test',
          fontSize: 16,
          fontWeight: 400,
          devicePixelRatio: 1,
          viewportWidth: 100,
          viewportHeight: 100,
          contentLeft: 0,
          contentTop: 0,
          contentWidth: 100,
          contentHeight: 100,
          lineHeight: 1,
          renderedLineHeight: 16,
          letterSpacing: 0,
          paragraphSpacingTenths: 0,
          pageMode: 'horizontal',
        ),
        pages: [
          ReaderPageSnapshot(index: 0, text: '甲', start: 0, end: 1),
          ReaderPageSnapshot(index: 1, text: '丁', start: 3, end: 4),
        ],
      );

      expect(
        snapshot.validate(source),
        contains('page 1 skips non-layout source text'),
      );
    },
  );

  test('snapshot validation allows an original-compatible display newline', () {
    const source = '甲乙';
    const snapshot = ReaderPaginationSnapshot(
      fixtureId: 'display-newline',
      sourceTextLength: source.length,
      chapterIndex: 0,
      chapterCount: 1,
      chapterStart: 0,
      chapterEnd: source.length,
      config: ReaderPaginationSnapshotConfig(
        fontFamily: 'test',
        fontSize: 16,
        fontWeight: 400,
        devicePixelRatio: 1,
        viewportWidth: 100,
        viewportHeight: 100,
        contentLeft: 0,
        contentTop: 0,
        contentWidth: 100,
        contentHeight: 100,
        lineHeight: 1,
        renderedLineHeight: 16,
        letterSpacing: 0,
        paragraphSpacingTenths: 0,
        pageMode: 'horizontal',
      ),
      pages: [ReaderPageSnapshot(index: 0, text: '甲乙\n', start: 0, end: 2)],
    );

    expect(snapshot.validate(source), isEmpty);
  });

  test('snapshot config records visual styles that do not alter ranges', () {
    const config = ReaderPaginationSnapshotConfig(
      fontFamily: 'sans-serif',
      fontSize: 16,
      fontWeight: 400,
      devicePixelRatio: 2,
      viewportWidth: 360,
      viewportHeight: 640,
      contentLeft: 16,
      contentTop: 24,
      contentWidth: 328,
      contentHeight: 560,
      lineHeight: 1.5,
      renderedLineHeight: 28.125,
      letterSpacing: 0,
      paragraphSpacingTenths: 0,
      pageMode: 'horizontal',
      textFullJustify: true,
      titleFontSize: 16,
      titleFontWeight: 700,
    );

    final decoded = ReaderPaginationSnapshotConfig.fromJson(config.toJson());
    expect(decoded.textFullJustify, isTrue);
    expect(decoded.titleFontSize, 16);
    expect(decoded.titleFontWeight, 700);
  });
}
