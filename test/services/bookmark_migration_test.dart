import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/models/book.dart';
import 'package:legado_flutter/services/bookmark_migration_service.dart';
import 'package:legado_flutter/services/bookmark_service.dart';
import 'package:legado_flutter/src/rust/api.dart' as rust_api;

void main() {
  test('legacy bookmark conversion maps book metadata and stable fields', () {
    const note = rust_api.NoteDto(
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
}
