import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/reader/book_progress.dart';

void main() {
  test(
    'BookProgress preserves JSON fields and UTF-16 position comparisons',
    () {
      final progress = BookProgress.fromJson({
        'name': '书名',
        'author': '作者',
        'durChapterIndex': 3,
        'durChapterPos': 8,
        'durChapterTime': 10,
        'durChapterTitle': '第三章',
      });

      expect(progress.toJson()['durChapterPos'], 8);
      expect(progress.isAheadOf(chapterIndex: 3, chapterPos: 7), isTrue);
      expect(progress.isBehind(chapterIndex: 3, chapterPos: 9), isTrue);
      expect(progress.copyWith(durChapterIndex: 4).durChapterIndex, 4);
    },
  );

  test('BookProgress supplies legacy defaults', () {
    final progress = BookProgress.fromJson(const {});

    expect(progress.name, isEmpty);
    expect(progress.durChapterIndex, 0);
    expect(progress.durChapterPos, 0);
    expect(progress.durChapterTime, 0);
  });
}
