import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/reader/reading_scroll_position_mapper.dart';

void main() {
  test(
    'derives max scroll extent and clamps content smaller than viewport',
    () {
      expect(
        ReadingScrollPositionMapper.maxScrollExtent(
          viewportHeight: 400,
          contentHeight: 1000,
        ),
        600,
      );
      expect(
        ReadingScrollPositionMapper.maxScrollExtent(
          viewportHeight: 1000,
          contentHeight: 400,
        ),
        0,
      );
    },
  );

  test('maps the top, middle, and bottom of a scrollable chapter', () {
    int position(double offset) =>
        ReadingScrollPositionMapper.chapterPositionForOffset(
          offset: offset,
          viewportHeight: 400,
          contentHeight: 1000,
          contentLength: 1000,
        );

    expect(position(0), 0);
    expect(position(300), 500);
    expect(position(600), 1000);
  });

  test('clamps offsets outside the scroll range', () {
    int position(double offset) =>
        ReadingScrollPositionMapper.chapterPositionForOffset(
          offset: offset,
          viewportHeight: 400,
          contentHeight: 1000,
          contentLength: 1000,
        );

    expect(position(-50), 0);
    expect(position(650), 1000);
    expect(position(double.infinity), 1000);
  });

  test('returns the chapter start when content cannot scroll', () {
    expect(
      ReadingScrollPositionMapper.chapterPositionForOffset(
        offset: 200,
        viewportHeight: 1000,
        contentHeight: 800,
        contentLength: 500,
      ),
      0,
    );
  });

  test('uses Dart UTF-16 length for supplementary characters', () {
    const chapter = '甲😀乙';
    expect(chapter.length, 4);
    expect(
      ReadingScrollPositionMapper.chapterPositionForOffset(
        offset: 50,
        viewportHeight: 100,
        contentHeight: 200,
        contentLength: chapter.length,
      ),
      2,
    );
  });

  test(
    'handles invalid dimensions and length without producing invalid offsets',
    () {
      expect(
        ReadingScrollPositionMapper.chapterPositionForOffset(
          offset: double.nan,
          viewportHeight: double.infinity,
          contentHeight: -1,
          contentLength: -5,
        ),
        0,
      );
      expect(
        ReadingScrollPositionMapper.maxScrollExtent(
          viewportHeight: double.nan,
          contentHeight: double.infinity,
        ),
        0,
      );
    },
  );
}
