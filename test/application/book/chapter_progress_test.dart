import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/book/chapter_progress_migrator.dart';
import 'package:legado_flutter/domain/book/chapter.dart';

Chapter _chapter({
  required String id,
  required String title,
  required String url,
  required int index,
}) {
  return Chapter(
    id: id,
    bookId: 'book-1',
    title: title,
    index: index,
    url: url,
  );
}

void main() {
  group('ChapterProgress', () {
    test('is an immutable value object with copyWith', () {
      const progress = ChapterProgress(chapterIndex: 3, chapterPos: 24);

      expect(
        progress,
        equals(const ChapterProgress(chapterIndex: 3, chapterPos: 24)),
      );
      expect(progress.copyWith(chapterPos: 25).chapterIndex, 3);
      expect(progress.copyWith(chapterPos: 25).chapterPos, 25);
    });
  });

  group('ChapterProgressMigrator', () {
    test(
      'keeps a UTF-16 chapter position when the URL identifies the chapter',
      () {
        final result = ChapterProgressMigrator.migrate(
          oldChapters: [
            _chapter(
              id: 'old',
              title: '第一章',
              url: 'https://book/ch-1',
              index: 0,
            ),
          ],
          newChapters: [
            _chapter(
              id: 'new',
              title: '第一章（更新）',
              url: 'https://book/ch-1',
              index: 0,
            ),
          ],
          oldChapterIndex: 0,
          // "A😀B" has four UTF-16 code units; position 3 must remain a code-unit offset.
          oldChapterPos: 3,
          newChapterLength: 4,
        );

        expect(result, const ChapterProgress(chapterIndex: 0, chapterPos: 3));
      },
    );

    test(
      'falls back to the title and clamps the retained reading position',
      () {
        final result = ChapterProgressMigrator.migrate(
          oldChapters: [
            _chapter(
              id: 'old',
              title: '第二章',
              url: 'https://old/ch-2',
              index: 0,
            ),
          ],
          newChapters: [
            _chapter(
              id: 'new',
              title: '第二章',
              url: 'https://new/ch-2',
              index: 0,
            ),
          ],
          oldChapterIndex: 0,
          oldChapterPos: 80,
          newChapterLength: 40,
        );

        expect(result, const ChapterProgress(chapterIndex: 0, chapterPos: 40));
      },
    );
  });
}
