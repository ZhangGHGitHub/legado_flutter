import 'dart:convert';
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

const _phase = String.fromEnvironment('R1_ROOM_PHASE', defaultValue: 'all');
const _dataset = String.fromEnvironment(
  'R1_ROOM_DATASET',
  defaultValue: 'real',
);
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

int _legacyRoomImportCount(String rawBackupJson) {
  final value = jsonDecode(rawBackupJson);
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Rust 备份不是数据库 JSON 对象');
  }
  final imports = value['legacyRoomImports'];
  if (imports is! List) {
    throw const FormatException('Rust 备份缺少 legacyRoomImports 数组');
  }
  return imports.length;
}

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
    if (_phase == 'import' || _phase == 'all') {
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

    if (_phase == 'import' || _phase == 'all') {
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
      expect(importedBooks.any((book) => book.id == 'r1-device-book'), isTrue);
      final sourceBooks = importedBooks
          .where((book) => book.id != 'r1-device-book')
          .toList();
      expect(sourceBooks, isNotEmpty, reason: '真实 Room 源库至少应导入一本书');
      final importedBook = sourceBooks.first;
      expect(importedBook.id, isNotEmpty);
      expect(importedBook.name, isNotEmpty);
      expect(importedBook.author, isNotEmpty);
      expect(importedBook.sourceUrl, importedBook.id);
      expect(importedBook.bookSourceUrl, isNotEmpty);
      expect(importedBook.tocUrl, isNotEmpty);
      expect(importedBook.durChapterIndex, greaterThanOrEqualTo(0));
      expect(importedBook.currentPageIndex, greaterThanOrEqualTo(0));
      expect(importedBook.readIteration, greaterThanOrEqualTo(0));

      final importedChapters = await database.getChapters(importedBook.id);
      expect(importedChapters, isNotEmpty);
      expect(importedChapters.length, report.counts['chapters']);
      final chapterIds = <String>{};
      for (final chapter in importedChapters) {
        expect(chapter.id, isNotEmpty);
        expect(chapterIds.add(chapter.id), isTrue, reason: '章节 ID 不得重复');
        expect(
          chapter.id,
          Chapter.idFor(
            bookId: importedBook.id,
            url: chapter.url,
            index: chapter.index,
          ),
        );
      }
      expect(report.counts['detailedReadRecords'], greaterThan(0));
      expect(report.counts['readRecord'], greaterThan(0));
      expect(
        report.warnings.any((warning) => warning.contains('readRecord')),
        isTrue,
        reason: '真实 Room readRecord 仍应保留 archive-only warning',
      );

      if (_dataset == 'fixture') {
        expect(importedBook.id, 'book-android');
        expect(importedBook.name, 'Android 迁移测试书');
        expect(importedBook.author, '测试作者');
        expect(importedBook.bookSourceUrl, 'https://source.android.test');
        expect(importedBook.tocUrl, 'https://toc.android.test');
        expect(importedBook.durChapterIndex, 0);
        expect(importedBook.currentPageIndex, 17);
        expect(importedBook.readIteration, 2);
        expect(importedBook.readConfig.extra['fontSize'], 20);
        expect(importedChapters, hasLength(1));
        expect(importedChapters.single.title, '第一章');
        expect(importedChapters.single.index, 0);
      }
      if (_phase != 'all') return;
    }

    expect(<String>{'all', 'verify'}, contains(_phase));
    final persistedBooks = await database.getBooks();
    expect(persistedBooks.any((book) => book.id == 'r1-device-book'), isTrue);
    final persistedSourceBooks = persistedBooks
        .where((book) => book.id != 'r1-device-book')
        .toList();
    expect(persistedSourceBooks, isNotEmpty);

    final duplicateBackupPath = p.join(
      documents.path,
      'r1-room-gate-duplicate.json',
    );
    final duplicateBackupFile = File(duplicateBackupPath);
    if (await duplicateBackupFile.exists()) await duplicateBackupFile.delete();
    final booksBeforeDuplicate = await database.getBooks();
    final archivesBeforeDuplicate = _legacyRoomImportCount(
      FrbBackupPort().exportBackup(),
    );
    final duplicate = importService.importDatabase(
      sourcePath: _sourcePath,
      backupPath: duplicateBackupPath,
      replace: false,
    );
    expect(duplicate.skippedDuplicate, isTrue);
    expect(duplicate.backupWritten, isFalse);
    expect(duplicate.backupPath, duplicateBackupPath);
    expect(await duplicateBackupFile.exists(), isFalse);
    expect(
      (await database.getBooks()).length,
      booksBeforeDuplicate.length,
      reason: '重复 Room 导入不得增加目标业务书籍数',
    );
    expect(
      _legacyRoomImportCount(FrbBackupPort().exportBackup()),
      archivesBeforeDuplicate,
      reason: '重复 Room 导入不得增加 legacyRoomImports 归档数',
    );

    // 重复导入已存在时，Rust 允许省略备份路径；此调用仍经 application
    // service、FRB port 和 generated FRB API，不能用手写报告替代。
    final booksBeforeNullBackupDuplicate = await database.getBooks();
    final archivesBeforeNullBackupDuplicate = _legacyRoomImportCount(
      FrbBackupPort().exportBackup(),
    );
    final duplicateWithoutBackup = importService.importDatabase(
      sourcePath: _sourcePath,
      backupPath: null,
      replace: false,
    );
    expect(duplicateWithoutBackup.skippedDuplicate, isTrue);
    expect(duplicateWithoutBackup.backupWritten, isFalse);
    expect(duplicateWithoutBackup.backupPath, isNull);
    expect(
      (await database.getBooks()).map((book) => book.id).toList(),
      booksBeforeNullBackupDuplicate.map((book) => book.id).toList(),
      reason: '省略备份路径的重复 Room 导入不得修改目标业务书籍',
    );
    expect(
      _legacyRoomImportCount(FrbBackupPort().exportBackup()),
      archivesBeforeNullBackupDuplicate,
      reason: '省略备份路径的重复 Room 导入不得增加 legacyRoomImports 归档数',
    );

    final backupFile = await backupService.backupToLocalFile();
    final backupBytes = await backupFile.readAsBytes();
    expect(backupBytes, isNotEmpty);
    await database.clearAll();
    expect(await database.getBooks(), isEmpty);
    await backupService.restoreFromBytes(backupBytes);
    final restoredBooks = await database.getBooks();
    expect(restoredBooks.any((book) => book.id == 'r1-device-book'), isTrue);
    for (final book in persistedBooks) {
      expect(
        restoredBooks.any((restored) => restored.id == book.id),
        isTrue,
        reason: '备份恢复不得丢失书籍 ${book.id}',
      );
    }
  });
}
