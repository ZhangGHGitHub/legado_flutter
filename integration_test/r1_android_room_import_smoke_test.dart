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
      expect(report.preservedRows.length, greaterThanOrEqualTo(23));
      expect(report.archiveOnlyTables, contains('book_groups'));
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
      expect((await database.getBooks()).single.id, 'r1-device-book');
      return;
    }

    expect(_phase, 'verify');
    final persistedBooks = await database.getBooks();
    expect(persistedBooks.single.id, 'r1-device-book');

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
    expect((await database.getBooks()).single.id, 'r1-device-book');
  });
}
