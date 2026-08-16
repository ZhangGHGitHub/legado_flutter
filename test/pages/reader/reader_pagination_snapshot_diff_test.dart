import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/features/reader/reader_pagination_snapshot.dart';
import 'package:legado_flutter/features/reader/reader_pagination_snapshot_diff.dart';

ReaderPaginationSnapshot _snapshot({required List<ReaderPageSnapshot> pages}) {
  return ReaderPaginationSnapshot(
    fixtureId: 'fixture',
    sourceTextLength: 4,
    chapterIndex: 0,
    chapterCount: 1,
    chapterStart: 0,
    chapterEnd: 4,
    config: const ReaderPaginationSnapshotConfig(
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
    ),
    pages: pages,
  );
}

void main() {
  test('equal snapshots produce no differences', () {
    final snapshot = _snapshot(
      pages: const [
        ReaderPageSnapshot(index: 0, text: '甲乙丙丁', start: 0, end: 4),
      ],
    );
    expect(
      ReaderPaginationSnapshotDiff.compare(snapshot, snapshot).differences,
      isEmpty,
    );
  });

  test('reports page ranges, text and count differences', () {
    final expected = _snapshot(
      pages: const [ReaderPageSnapshot(index: 0, text: '甲乙', start: 0, end: 2)],
    );
    final actual = _snapshot(
      pages: const [
        ReaderPageSnapshot(index: 0, text: '甲', start: 0, end: 1),
        ReaderPageSnapshot(index: 1, text: '乙丙丁', start: 1, end: 4),
      ],
    );
    final diff = ReaderPaginationSnapshotDiff.compare(expected, actual);
    expect(diff.differences, contains('page count: expected 1, actual 2'));
    expect(
      diff.differences,
      contains('page 0 range: expected 0..2, actual 0..1'),
    );
    expect(
      diff.differences,
      contains('page 0 text differs: expected length 2, actual length 1'),
    );
  });
}
