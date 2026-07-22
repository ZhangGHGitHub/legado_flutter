import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/pages/reader/reader_paginator.dart';

void main() {
  test('image styles preserve original width semantics', () {
    const natural = Size(120, 60);

    expect(
      ReaderImageLayout.displaySize(
        natural: natural,
        maxWidth: 200,
        style: 'DEFAULT',
      ),
      const Size(120, 60),
    );
    expect(
      ReaderImageLayout.displaySize(
        natural: natural,
        maxWidth: 200,
        style: 'FULL',
      ),
      const Size(200, 100),
    );
    expect(
      ReaderImageLayout.displaySize(
        natural: const Size(400, 200),
        maxWidth: 200,
        style: 'DEFAULT',
      ),
      const Size(200, 100),
    );
  });

  test('image URL widths support percentages and pixel values', () {
    expect(ReaderImageLayout.parseWidth('50%', 300), 150);
    expect(ReaderImageLayout.parseWidth('120', 300), 120);
    expect(ReaderImageLayout.parseWidth('bad', 300), isNull);
    expect(
      ReaderImageLayout.displaySize(
        natural: const Size(400, 200),
        maxWidth: 300,
        style: 'DEFAULT',
        widthOverride: 150,
      ),
      const Size(150, 75),
    );
    expect(
      ReaderImageLayout.displaySize(
        natural: const Size(400, 200),
        maxWidth: 300,
        style: 'FULL',
        widthOverride: 150,
      ),
      const Size(300, 150),
    );
  });

  testWidgets('pagination exposes contiguous character ranges', (tester) async {
    final text = List<String>.filled(
      80,
      '这是中文正文，包含英文 words 和数字 123。',
    ).join('\n');
    final pages = ReaderPaginator.paginate(
      text: text,
      style: const TextStyle(fontSize: 16, height: 1.5),
      maxWidth: 150,
      maxHeight: 72,
    );

    expect(pages, isNotEmpty);
    expect(pages.first.start, 0);
    expect(pages.last.end, text.length);
    for (var i = 1; i < pages.length; i++) {
      expect(pages[i].start, pages[i - 1].end);
    }
    expect(pages.map((page) => page.text).join(), text);
    expect(
      pages
          .skip(1)
          .every(
            (page) =>
                page.text.isEmpty ||
                !RegExp(r'^[，。！？；：、」』】）]').hasMatch(page.text),
          ),
      isTrue,
    );
  });

  testWidgets(
    'paragraph spacing changes height without adding source blank lines',
    (tester) async {
      const text = '第一段\n第二段\n第三段';
      final withoutSpacing = ReaderPaginator.paginate(
        text: text,
        style: const TextStyle(fontSize: 16, height: 1),
        maxWidth: 300,
        maxHeight: 32,
      );
      final withSpacing = ReaderPaginator.paginate(
        text: text,
        style: const TextStyle(fontSize: 16, height: 1),
        maxWidth: 300,
        maxHeight: 32,
        paragraphSpacingTenths: 2,
      );
      expect(withoutSpacing.map((page) => page.text).join(), text);
      expect(withSpacing.map((page) => page.text).join(), text);
      expect(withSpacing.length, greaterThan(withoutSpacing.length));
      expect(withSpacing.first.end, lessThan(text.length));
    },
  );

  testWidgets('mixed text keeps forbidden punctuation off page starts', (
    tester,
  ) async {
    const text =
        '中文与English混排，数字123和URL https://example.com/a_long_path。'
        '下一句继续；不要在页首出现标点。';
    final pages = ReaderPaginator.paginate(
      text: text,
      style: const TextStyle(fontSize: 16, height: 1.2),
      maxWidth: 115,
      maxHeight: 48,
    );

    expect(pages, isNotEmpty);
    expect(pages.first.start, 0);
    expect(pages.last.end, text.length);
    for (var i = 1; i < pages.length; i++) {
      expect(pages[i].start, pages[i - 1].end);
      expect(
        pages[i].text.isEmpty ||
            !RegExp(r'^[，。！？；：、」』】）]').hasMatch(pages[i].text),
        isTrue,
      );
    }
  });

  testWidgets('newpage forces a page boundary and stays out of page text', (
    tester,
  ) async {
    const text = '第一段\n[newpage]\n第二段';
    final pages = ReaderPaginator.paginate(
      text: text,
      style: const TextStyle(fontSize: 16, height: 1),
      maxWidth: 300,
      maxHeight: 200,
    );

    expect(pages.map((page) => page.text).toList(), ['第一段\n', '第二段']);
    expect(pages.first.start, 0);
    expect(pages.first.end, 4);
    expect(pages.last.start, 14);
    expect(pages.last.end, text.length);
    expect(pages.map((page) => page.text).join(), '第一段\n第二段');
    expect(pages.every((page) => !page.text.contains('[newpage]')), isTrue);
    expect(ReaderPaginator.pageIndexForPosition(pages, 0), 0);
    expect(ReaderPaginator.pageIndexForPosition(pages, 4), 1);
    expect(ReaderPaginator.pageIndexForPosition(pages, 14), 1);
    expect(ReaderPaginator.pageIndexForPosition(pages, text.length), 1);
  });

  testWidgets('placeholder dimensions participate in pagination measurement', (
    tester,
  ) async {
    const image = '\uFFFC';
    const text = '前\n$image\n后';
    final pages = ReaderPaginator.paginate(
      text: text,
      style: const TextStyle(fontSize: 16, height: 1),
      maxWidth: 200,
      maxHeight: 40,
      placeholders: const [
        ReaderPaginatorPlaceholder(start: 2, end: 3, width: 30, height: 100),
      ],
    );
    expect(pages.map((page) => page.text).join(), text);
    expect(pages, hasLength(3));
    expect(pages.map((page) => page.start).toList(), [0, 1, 3]);
    expect(pages.map((page) => page.end).toList(), [1, 3, 5]);
    expect(pages.map((page) => page.text).toList(), ['前', '\n$image', '\n后']);
  });

  testWidgets(
    'placeholder size changes page boundaries without changing offsets',
    (tester) async {
      const image = '\uFFFC';
      const text = '甲\n$image\n乙\n丙';
      List<ReaderPageSlice> paginate(double height) => ReaderPaginator.paginate(
        text: text,
        style: const TextStyle(fontSize: 16, height: 1),
        maxWidth: 200,
        maxHeight: 40,
        placeholders: [
          ReaderPaginatorPlaceholder(
            start: 2,
            end: 3,
            width: 30,
            height: height,
          ),
        ],
      );

      final small = paginate(16);
      final large = paginate(80);
      expect(small.map((page) => page.text).join(), text);
      expect(large.map((page) => page.text).join(), text);
      expect(large.length, greaterThan(small.length));
      expect(large.map((page) => <int>[page.start, page.end]).toList(), [
        [0, 1],
        [1, 3],
        [3, 7],
      ]);
    },
  );

  testWidgets('placeholder without dimensions keeps fixed fallback bounds', (
    tester,
  ) async {
    const text = '前\uFFFC后';
    final pages = ReaderPaginator.paginate(
      text: text,
      style: const TextStyle(fontSize: 16, height: 1),
      maxWidth: 100,
      maxHeight: 100,
    );

    expect(pages.map((page) => page.text).join(), text);
    expect(pages, hasLength(1));
  });

  testWidgets('SINGLE image style gives each image an independent page', (
    tester,
  ) async {
    const image = '\uFFFC';
    const text = '前\n$image\n后';
    final pages = ReaderPaginator.paginate(
      text: text,
      style: const TextStyle(fontSize: 16, height: 1),
      maxWidth: 200,
      maxHeight: 100,
      placeholders: const [
        ReaderPaginatorPlaceholder(start: 2, end: 3, width: 200, height: 80),
      ],
      singleImageStyle: true,
    );

    expect(pages.map((page) => page.text).toList(), ['前\n', image, '\n后']);
    expect(pages.map((page) => <int>[page.start, page.end]).toList(), [
      [0, 2],
      [2, 3],
      [3, 5],
    ]);
    expect(pages.map((page) => page.text).join(), text);
  });
}
