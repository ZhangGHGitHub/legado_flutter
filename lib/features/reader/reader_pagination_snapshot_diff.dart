import 'reader_pagination_snapshot.dart';

/// Structured differences between an original and rewritten reader snapshot.
class ReaderPaginationSnapshotDiff {
  final List<String> differences;

  const ReaderPaginationSnapshotDiff(this.differences);

  bool get isEmpty => differences.isEmpty;

  static ReaderPaginationSnapshotDiff compare(
    ReaderPaginationSnapshot expected,
    ReaderPaginationSnapshot actual,
  ) {
    final differences = <String>[];
    if (expected.fixtureId != actual.fixtureId) {
      differences.add(
        'fixtureId: expected ${expected.fixtureId}, actual ${actual.fixtureId}',
      );
    }
    if (expected.sourceTextLength != actual.sourceTextLength) {
      differences.add(
        'sourceTextLength: expected ${expected.sourceTextLength}, actual ${actual.sourceTextLength}',
      );
    }
    if (expected.chapterIndex != actual.chapterIndex ||
        expected.chapterCount != actual.chapterCount ||
        expected.chapterStart != actual.chapterStart ||
        expected.chapterEnd != actual.chapterEnd) {
      differences.add(
        'chapter boundary: expected ${_chapter(expected)}, actual ${_chapter(actual)}',
      );
    }
    _compareConfig(expected.config, actual.config, differences);
    if (expected.pages.length != actual.pages.length) {
      differences.add(
        'page count: expected ${expected.pages.length}, actual ${actual.pages.length}',
      );
    }
    final count = expected.pages.length < actual.pages.length
        ? expected.pages.length
        : actual.pages.length;
    for (var i = 0; i < count; i++) {
      final expectedPage = expected.pages[i];
      final actualPage = actual.pages[i];
      if (expectedPage.index != actualPage.index) {
        differences.add(
          'page $i index: expected ${expectedPage.index}, actual ${actualPage.index}',
        );
      }
      if (expectedPage.start != actualPage.start ||
          expectedPage.end != actualPage.end) {
        differences.add(
          'page $i range: expected ${expectedPage.start}..${expectedPage.end}, actual ${actualPage.start}..${actualPage.end}',
        );
      }
      if (expectedPage.text != actualPage.text) {
        differences.add(
          'page $i text differs: expected length ${expectedPage.text.length}, actual length ${actualPage.text.length}',
        );
      }
    }
    return ReaderPaginationSnapshotDiff(differences);
  }
}

String _chapter(ReaderPaginationSnapshot snapshot) {
  return '${snapshot.chapterIndex}/${snapshot.chapterCount} ${snapshot.chapterStart}..${snapshot.chapterEnd}';
}

void _compareConfig(
  ReaderPaginationSnapshotConfig expected,
  ReaderPaginationSnapshotConfig actual,
  List<String> differences,
) {
  final expectedJson = expected.toJson();
  final actualJson = actual.toJson();
  if (expectedJson.toString() != actualJson.toString()) {
    differences.add('layout config differs');
  }
}
