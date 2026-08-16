import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/help/bookmark_hint.dart';

void main() {
  test('parses page from bookmark hint', () {
    expect(bookmarkPageIndexFromNote('书签 · 第3/10页'), 2);
    expect(bookmarkPageIndexFromNote('书签 · 第1/1页'), 0);
  });

  test('returns null for non-page hints', () {
    expect(bookmarkPageIndexFromNote('书签 · 滚动位置'), isNull);
    expect(bookmarkPageIndexFromNote('普通想法'), isNull);
  });

  test('pageIndexForChapterPos maps offset into pages', () {
    final pages = ['aaaa', 'bbbb', 'cccc'];
    expect(pageIndexForChapterPos(pages, 0), 0);
    expect(pageIndexForChapterPos(pages, 3), 0);
    expect(pageIndexForChapterPos(pages, 4), 1);
    expect(pageIndexForChapterPos(pages, 8), 2);
  });

  test('chapterPosForPageIndex is inverse of page starts', () {
    final pages = ['aaaa', 'bbbb', 'cccc'];
    expect(chapterPosForPageIndex(pages, 0), 0);
    expect(chapterPosForPageIndex(pages, 1), 4);
    expect(chapterPosForPageIndex(pages, 2), 8);
  });

  test('chapterPosForScrollOffset maps scroll ratio to content offset', () {
    expect(
      chapterPosForScrollOffset(
        offset: 0,
        maxScrollExtent: 900,
        contentLength: 1000,
      ),
      0,
    );
    expect(
      chapterPosForScrollOffset(
        offset: 450,
        maxScrollExtent: 900,
        contentLength: 1000,
      ),
      500,
    );
    expect(
      chapterPosForScrollOffset(
        offset: 1200,
        maxScrollExtent: 900,
        contentLength: 1000,
      ),
      1000,
    );
  });
}
