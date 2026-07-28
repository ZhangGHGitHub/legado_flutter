import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/bridge/legado_db_bridge.dart';
import 'package:legado_flutter/bridge/legado_engine_bridge.dart';
import 'package:legado_flutter/database/database_helper.dart';
import 'package:legado_flutter/models/book.dart';
import 'package:legado_flutter/services/bookmark_migration_service.dart';
import 'package:legado_flutter/services/bookmark_service.dart';
import 'package:legado_flutter/services/note_service.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late bool rustReady;

  setUpAll(() async {
    await LegadoEngineBridge.tryInit();
    rustReady = LegadoEngineBridge.isAvailable;
    if (rustReady) {
      final tempDir = await Directory.systemTemp.createTemp('legado_bookmark_');
      await LegadoDbBridge.init(
        dbPathOverride: p.join(tempDir.path, 'legado.db'),
      );
    }
  });

  test(
    'BookmarkService saves, lists and deletes independent bookmarks',
    () async {
      if (!rustReady) return;

      const time = 1700000000123;
      expect(
        BookmarkService.save(
          time: time,
          bookId: 'b1',
          bookName: '测试书',
          bookAuthor: '测试作者',
          chapterIndex: 3,
          chapterPos: 88,
          chapterName: '第四章',
          bookText: '正文片段',
          content: '备注内容',
        ),
        time,
      );

      final rows = BookmarkService.list(bookId: 'b1');
      expect(rows, hasLength(1));
      expect(rows.single.bookName, '测试书');
      expect(rows.single.bookAuthor, '测试作者');
      expect(rows.single.chapterIndex, 3);
      expect(rows.single.chapterPos, 88);
      expect(rows.single.chapterName, '第四章');
      expect(rows.single.bookText, '正文片段');
      expect(rows.single.content, '备注内容');

      BookmarkService.delete(time);
      expect(BookmarkService.list(bookId: 'b1'), isEmpty);

      final book = Book(id: 'b1', name: '测试书', author: '测试作者');
      await DatabaseHelper().insertBook(book);
      NoteService.save(
        id: 'legacy-bookmark',
        bookId: 'b1',
        chapterTitle: '第四章',
        selectedText: '旧正文',
        noteContent: '书签 · 第1页',
        position: 3,
        chapterPos: 88,
      );
      final legacy = NoteService.list(bookId: 'b1');
      expect(
        BookmarkMigrationService.migrateLegacyNoteSnapshots(
          notes: legacy,
          books: [book],
        ),
        1,
      );
      expect(
        BookmarkMigrationService.migrateLegacyNoteSnapshots(
          notes: legacy,
          books: [book],
        ),
        1,
      );
      final migrated = BookmarkService.list(bookId: 'b1');
      expect(migrated, hasLength(1));
      expect(migrated.single.bookAuthor, '测试作者');
      BookmarkService.delete(migrated.single.time);
      NoteService.delete('legacy-bookmark');
    },
  );
}
