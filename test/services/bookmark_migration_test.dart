import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/annotation/note_snapshot.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/services/bookmark_migration_service.dart';
import 'package:legado_flutter/services/bookmark_service.dart';

void main() {
  test('legacy bookmark conversion maps book metadata and stable fields', () {
    const note = NoteSnapshot(
      id: 'legacy-1',
      bookId: 'b1',
      chapterTitle: '第一章',
      selectedText: '原文片段',
      noteContent: '书签 · 第2页',
      position: 0,
      chapterPos: -1,
      createdAt: '2026-07-22 12:00:00',
    );
    final converted = BookmarkMigrationService.convertLegacyNotes(
      notes: const [note],
      books: {'b1': Book(id: 'b1', name: '测试书', author: '测试作者')},
    );

    expect(converted, hasLength(1));
    expect(converted.single.bookName, '测试书');
    expect(converted.single.bookAuthor, '测试作者');
    expect(converted.single.chapterPos, 0);
    expect(converted.single.bookText, '原文片段');
    expect(converted.single.content, isEmpty);
    expect(converted.single.time, greaterThan(0));
  });

  test('bookmark JSON accepts original fields and rejects invalid time', () {
    const raw = '''[
      {
        "time": 123,
        "bookName": "测试书",
        "bookAuthor": "作者",
        "chapterIndex": 2,
        "chapterPos": 9,
        "chapterName": "第三章",
        "bookText": "正文",
        "content": "备注"
      }
    ]''';
    final decoded = BookmarkService.decodeJson(raw);
    expect(decoded.single.bookId, isEmpty);
    expect(decoded.single.bookAuthor, '作者');
    expect(decoded.single.chapterPos, 9);

    final encoded = BookmarkService.encodeJson(decoded);
    expect(encoded, contains('"time": 123'));
    expect(encoded, contains('"chapterName": "第三章"'));

    expect(
      () => BookmarkService.decodeJson('[{"bookName":"坏数据"}]'),
      throwsFormatException,
    );
  });

  test('remote bookmark merge keeps the union and remote wins conflicts', () {
    const local = '''[
      {"time": 1, "bookName": "本地书签", "chapterIndex": 1},
      {"time": 2, "bookName": "仅本地", "chapterIndex": 2}
    ]''';
    const remote = '''[
      {"time": 1, "bookName": "远端更新", "chapterIndex": 3},
      {"time": 3, "bookName": "仅远端", "chapterIndex": 4}
    ]''';

    final merged = BookmarkService.decodeJson(
      BookmarkService.mergeRemoteJson(local, remote),
    );

    expect(merged, hasLength(3));
    expect(merged.map((bookmark) => bookmark.time), [1, 2, 3]);
    expect(merged.first.bookName, '远端更新');
    expect(merged.first.chapterIndex, 3);
  });
}
