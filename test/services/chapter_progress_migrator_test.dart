import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/services/chapter_progress_migrator.dart';

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
  test('reordered chapters follow the stable URL identity', () {
    final oldChapters = [
      _chapter(id: 'a', title: '第一章', url: '/a', index: 0),
      _chapter(id: 'b', title: '第二章', url: '/b', index: 1),
      _chapter(id: 'c', title: '第三章', url: '/c', index: 2),
    ];
    final newChapters = [oldChapters[2], oldChapters[0], oldChapters[1]];

    final result = ChapterProgressMigrator.migrate(
      oldChapters: oldChapters,
      newChapters: newChapters,
      oldChapterIndex: 1,
      oldChapterPos: 120,
    );

    expect(result.chapterIndex, 2);
    expect(result.chapterPos, 120);
  });

  test(
    'deleted chapter falls back to the clipped old index and resets position',
    () {
      final oldChapters = [
        _chapter(id: 'a', title: '第一章', url: '/a', index: 0),
        _chapter(id: 'b', title: '第二章', url: '/b', index: 1),
        _chapter(id: 'c', title: '第三章', url: '/c', index: 2),
      ];
      final newChapters = [oldChapters[0], oldChapters[2]];

      final result = ChapterProgressMigrator.migrate(
        oldChapters: oldChapters,
        newChapters: newChapters,
        oldChapterIndex: 1,
        oldChapterPos: 120,
      );

      expect(result.chapterIndex, 1);
      expect(result.chapterPos, 0);
    },
  );

  test('same URL keeps the position even when the title is refreshed', () {
    final result = ChapterProgressMigrator.migrate(
      oldChapters: [
        _chapter(id: 'old', title: '旧标题', url: 'https://book/ch-1', index: 0),
      ],
      newChapters: [
        _chapter(id: 'new', title: '新标题', url: 'https://book/ch-1', index: 0),
      ],
      oldChapterIndex: 0,
      oldChapterPos: 80,
    );

    expect(result.chapterIndex, 0);
    expect(result.chapterPos, 80);
  });

  test(
    'changed URL can keep the position when the title identifies the chapter',
    () {
      final result = ChapterProgressMigrator.migrate(
        oldChapters: [
          _chapter(id: 'old', title: '第二章', url: 'https://old/ch-2', index: 0),
        ],
        newChapters: [
          _chapter(id: 'new', title: '第二章', url: 'https://new/ch-2', index: 0),
        ],
        oldChapterIndex: 0,
        oldChapterPos: 80,
        newChapterLength: 40,
      );

      expect(result.chapterIndex, 0);
      expect(result.chapterPos, 40);
    },
  );

  test('empty and out-of-range directories produce safe zero positions', () {
    final empty = ChapterProgressMigrator.migrate(
      oldChapters: const [],
      newChapters: const [],
      oldChapterIndex: 12,
      oldChapterPos: 80,
    );
    final clipped = ChapterProgressMigrator.migrate(
      oldChapters: const [],
      newChapters: [_chapter(id: 'a', title: '第一章', url: '/a', index: 0)],
      oldChapterIndex: 12,
      oldChapterPos: 80,
    );

    expect(empty.chapterIndex, 0);
    expect(empty.chapterPos, 0);
    expect(clipped.chapterIndex, 0);
    expect(clipped.chapterPos, 0);
  });
}
