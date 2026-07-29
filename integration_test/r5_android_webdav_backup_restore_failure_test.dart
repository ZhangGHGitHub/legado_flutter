import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:legado_flutter/bridge/legado_db_bridge.dart';
import 'package:legado_flutter/bridge/legado_engine_bridge.dart';
import 'package:legado_flutter/database/database_helper.dart';
import 'package:legado_flutter/infrastructure/database/frb_backup_port.dart';
import 'package:legado_flutter/infrastructure/webdav/frb_webdav_repository.dart';
import 'package:legado_flutter/models/book.dart';
import 'package:legado_flutter/models/book_source.dart';
import 'package:legado_flutter/services/backup_service.dart';
import 'package:legado_flutter/services/webdav_prefs.dart';
import 'package:legado_flutter/services/webdav_setup_service.dart';

const _url = String.fromEnvironment(
  'R5_WEBDAV_URL',
  defaultValue: 'http://10.0.2.2:19080/',
);
const _user = 'legado';
const _password = 'legado-test';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('R5 Android WebDAV backup restore and failure strategy', (
    tester,
  ) async {
    await LegadoEngineBridge.tryInit();
    expect(LegadoEngineBridge.isAvailable, isTrue);

    final dbRoot = await Directory.systemTemp.createTemp('r5_backup_restore_');
    await LegadoDbBridge.init(dbPathOverride: '${dbRoot.path}/legado.db');
    expect(LegadoDbBridge.isReady, isTrue);

    final config = WebDavConfig(
      url: _url,
      account: _user,
      password: _password,
      dir: '/r5-backup-restore-${DateTime.now().millisecondsSinceEpoch}',
      device: 'R5 backup restore',
    );
    await WebDavPrefs.save(config);
    const repository = FrbWebDavRepository();
    await WebDavSetupService.initialize(config, repository: repository);

    final database = DatabaseHelper();
    final book = Book(
      id: 'r5-restore-book',
      name: 'R5 Restore Book',
      author: 'R5 Author',
      sourceUrl: 'https://book.test/r5',
      bookSourceUrl: 'https://source.test/r5',
      totalChapterNum: 12,
      durChapterIndex: 4,
      currentPageIndex: 7,
    );
    final source = BookSource(
      bookSourceUrl: 'https://source.test/r5',
      bookSourceName: 'R5 Restore Source',
    );
    await database.insertBook(book);
    await database.insertBookSource(source);

    final service = BackupService(webdav: repository, backup: FrbBackupPort());
    await service.backupToWebDav();
    final backups = await service.listWebDavBackups();
    expect(backups, isNotEmpty);
    final backupPath = backups.first.path;

    await database.clearAll();
    expect(await database.getBooks(), isEmpty);
    expect(await database.getBookSources(), isEmpty);

    await service.restoreFromWebDav(backupPath);
    expect((await database.getBooks()).single.name, book.name);
    expect((await database.getBooks()).single.durChapterIndex, 4);
    expect(
      (await database.getBookSources()).single.bookSourceName,
      source.bookSourceName,
    );

    const invalidZipPath = '/r5-invalid-backup.zip';
    const missingDatabasePath = '/r5-missing-database.json';
    await repository.upload(
      url: _url,
      username: _user,
      password: _password,
      remotePath: '${config.rootDir}$invalidZipPath',
      data: utf8.encode('not a zip'),
    );
    await repository.upload(
      url: _url,
      username: _user,
      password: _password,
      remotePath: '${config.rootDir}$missingDatabasePath',
      data: utf8.encode('{"version":1}'),
    );

    await expectLater(
      service.restoreFromWebDav('${config.rootDir}$invalidZipPath'),
      throwsA(isA<FormatException>()),
    );
    await expectLater(
      service.restoreFromWebDav('${config.rootDir}$missingDatabasePath'),
      throwsA(isA<FormatException>()),
    );
    await expectLater(
      service.restoreFromWebDav('${config.rootDir}/missing.zip'),
      throwsA(isNotNull),
    );

    // Failed restore/download must not clear the already restored local data.
    expect((await database.getBooks()).single.id, book.id);
    expect(
      (await database.getBookSources()).single.bookSourceUrl,
      source.bookSourceUrl,
    );
  });
}
