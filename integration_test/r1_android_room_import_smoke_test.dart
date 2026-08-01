import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:legado_flutter/bridge/legado_db_bridge.dart';
import 'package:legado_flutter/bridge/legado_engine_bridge.dart';
import 'package:legado_flutter/database/database_helper.dart';
import 'package:legado_flutter/infrastructure/database/frb_backup_port.dart';
import 'package:legado_flutter/infrastructure/database/frb_legacy_room_import_port.dart';
import 'package:legado_flutter/infrastructure/webdav/frb_webdav_repository.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/services/backup_service.dart';
import 'package:legado_flutter/services/legacy_room_import_service_factory.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const _phase = String.fromEnvironment('R1_ROOM_PHASE', defaultValue: 'import');
const _sourcePath = String.fromEnvironment(
  'R1_ROOM_SOURCE_PATH',
  defaultValue:
      '/data/user/0/com.legado.legado_flutter/files/r1/original_legado.db',
);

const _roomV99EntityTables = <String>{
  'books',
  'book_groups',
  'book_sources',
  'chapters',
  'replace_rules',
  'searchBooks',
  'search_keywords',
  'cookies',
  'rssSources',
  'bookmarks',
  'rssArticles',
  'rssReadRecords',
  'rssStars',
  'txtTocRules',
  'readRecord',
  'detailedReadRecord',
  'httpTTS',
  'caches',
  'ruleSubs',
  'dictRules',
  'keyboardAssists',
  'book_thoughts',
  'servers',
};

const _roomV99ArchiveOnlyTables = <String>{
  'book_groups',
  'searchBooks',
  'search_keywords',
  'cookies',
  'rssSources',
  'rssArticles',
  'rssReadRecords',
  'rssStars',
  'txtTocRules',
  'readRecord',
  'httpTTS',
  'caches',
  'ruleSubs',
  'dictRules',
  'keyboardAssists',
  'book_thoughts',
  'servers',
};

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('R1 Android Room import $_phase phase', (tester) async {
    await LegadoEngineBridge.tryInit();
    expect(LegadoEngineBridge.isAvailable, isTrue);

    final documents = await getApplicationDocumentsDirectory();
    final targetPath = p.join(documents.path, 'r1-room-gate.db');
    final preImportBackupPath = p.join(
      documents.path,
      'r1-room-gate-pre-import.json',
    );
    if (_phase == 'import') {
      final target = File(targetPath);
      if (await target.exists()) await target.delete();
      final preImportBackup = File(preImportBackupPath);
      if (await preImportBackup.exists()) await preImportBackup.delete();
    }

    await LegadoDbBridge.init(dbPathOverride: targetPath);
    expect(LegadoDbBridge.isReady, isTrue);

    final database = DatabaseHelper();
    final importService = LegacyRoomImportServices.create(
      FrbLegacyRoomImportPort(),
    );
    final backupService = BackupService(
      webdav: const FrbWebDavRepository(),
      backup: FrbBackupPort(),
    );

    if (_phase == 'import') {
      final report = importService.importDatabase(
        sourcePath: _sourcePath,
        backupPath: preImportBackupPath,
        replace: true,
      );
      expect(report.sourceRoomVersion, 99);
      expect(report.fingerprint, isNotEmpty);
      expect(
        report.preservedRows.keys.toSet(),
        _roomV99EntityTables,
        reason: 'Room v99 实体表集合必须完整且不能包含未知表',
      );
      expect(report.preservedRows, hasLength(_roomV99EntityTables.length));
      for (final table in _roomV99EntityTables) {
        final rowCount = report.preservedRows[table];
        expect(rowCount, isNotNull, reason: 'Room v99 实体表缺少逐表行数: $table');
        expect(
          rowCount,
          greaterThanOrEqualTo(0),
          reason: 'Room v99 实体表行数不能为负数: $table',
        );
      }
      for (final table in const ['books', 'sources', 'chapters']) {
        expect(
          report.counts[table],
          greaterThan(0),
          reason: 'Room 非空迁移前置失败: $table 没有可迁移行',
        );
      }
      expect(
        report.archiveOnlyTables.toSet(),
        _roomV99ArchiveOnlyTables,
        reason: 'Room v99 archive-only 表集合必须与迁移边界一致',
      );
      expect(
        report.archiveOnlyTables,
        hasLength(_roomV99ArchiveOnlyTables.length),
      );
      expect(report.backupWritten, isTrue);
      expect(await File(preImportBackupPath).exists(), isTrue);

      await database.insertBook(
        Book(
          id: 'r1-device-book',
          name: 'R1 device persistence',
          author: 'R1',
          sourceUrl: 'https://book.test/r1',
          bookSourceUrl: 'https://source.test/r1',
          durChapterIndex: 2,
          currentPageIndex: 9,
        ),
      );
      final importedBooks = await database.getBooks();
      expect(importedBooks.any((book) => book.id == 'book-android'), isTrue);
      expect(importedBooks.any((book) => book.id == 'r1-device-book'), isTrue);
      final importedBook = importedBooks.firstWhere(
        (book) => book.id == 'book-android',
      );
      expect(importedBook.name, 'Android 迁移测试书');
      expect(importedBook.author, '测试作者');
      expect(importedBook.sourceUrl, 'book-android');
      expect(importedBook.bookSourceUrl, 'https://source.android.test');
      expect(importedBook.tocUrl, 'https://toc.android.test');
      expect(importedBook.durChapterIndex, 0);
      expect(importedBook.currentPageIndex, 17);
      expect(importedBook.readIteration, 2);
      expect(importedBook.readConfig.extra['fontSize'], 20);

      final importedChapters = await database.getChapters('book-android');
      expect(importedChapters, hasLength(1));
      expect(
        importedChapters.single.id,
        Chapter.idFor(
          bookId: 'book-android',
          url: 'https://source.android.test/chapter/1',
          index: 0,
        ),
      );
      expect(importedChapters.single.title, '第一章');
      expect(importedChapters.single.index, 0);
      return;
    }

    expect(_phase, 'verify');
    final persistedBooks = await database.getBooks();
    expect(persistedBooks.any((book) => book.id == 'book-android'), isTrue);
    expect(persistedBooks.any((book) => book.id == 'r1-device-book'), isTrue);

    final duplicate = importService.importDatabase(
      sourcePath: _sourcePath,
      backupPath: preImportBackupPath,
      replace: false,
    );
    expect(duplicate.skippedDuplicate, isTrue);

    final backupFile = await backupService.backupToLocalFile();
    final backupBytes = await backupFile.readAsBytes();
    expect(backupBytes, isNotEmpty);
    await database.clearAll();
    expect(await database.getBooks(), isEmpty);
    await backupService.restoreFromBytes(backupBytes);
    final restoredBooks = await database.getBooks();
    expect(restoredBooks.any((book) => book.id == 'book-android'), isTrue);
    expect(restoredBooks.any((book) => book.id == 'r1-device-book'), isTrue);
  });
}
