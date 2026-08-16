import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/reader/reading_position_mapper.dart';

void main() {
  final pages = [
    const ReadingPageRange(text: '甲乙', start: 0, end: 2),
    const ReadingPageRange(text: '丙丁', start: 5, end: 7),
    const ReadingPageRange(text: '戊', start: 7, end: 8),
  ];

  test('maps chapter positions with half-open ranges and gaps', () {
    expect(ReadingPositionMapper.pageIndexForPosition(pages, 0), 0);
    expect(ReadingPositionMapper.pageIndexForPosition(pages, 1), 0);
    expect(ReadingPositionMapper.pageIndexForPosition(pages, 2), 1);
    expect(ReadingPositionMapper.pageIndexForPosition(pages, 4), 1);
    expect(ReadingPositionMapper.pageIndexForPosition(pages, 5), 1);
    expect(ReadingPositionMapper.pageIndexForPosition(pages, 8), 2);
  });

  test('maps page indexes back to stable chapter starts', () {
    expect(ReadingPositionMapper.chapterPositionForPage(pages, -1), 0);
    expect(ReadingPositionMapper.chapterPositionForPage(pages, 1), 5);
    expect(ReadingPositionMapper.chapterPositionForPage(pages, 99), 7);
    expect(ReadingPositionMapper.chapterPositionForPage([], 0), 0);
  });

  test(
    'chapter position has priority over page index and -1 means last page',
    () {
      expect(
        ReadingPositionMapper.resolvePageIndex(
          pages: pages,
          chapterPosition: 5,
          requestedPageIndex: 0,
        ),
        1,
      );
      expect(
        ReadingPositionMapper.resolvePageIndex(
          pages: pages,
          requestedPageIndex: -1,
        ),
        2,
      );
      expect(
        ReadingPositionMapper.resolvePageIndex(
          pages: pages,
          requestedPageIndex: 99,
        ),
        2,
      );
    },
  );
}
