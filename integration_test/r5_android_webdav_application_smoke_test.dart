import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:legado_flutter/bridge/legado_db_bridge.dart';
import 'package:legado_flutter/bridge/legado_engine_bridge.dart';
import 'package:legado_flutter/domain/annotation/bookmark_snapshot.dart';
import 'package:legado_flutter/infrastructure/database/frb_backup_port.dart';
import 'package:legado_flutter/infrastructure/database/frb_legacy_room_import_port.dart';
import 'package:legado_flutter/infrastructure/file_system/backup_local_file_adapter.dart';
import 'package:legado_flutter/infrastructure/preferences/shared_preferences_book_progress_sync_store.dart';
import 'package:legado_flutter/infrastructure/webdav/frb_webdav_repository.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/models/book_progress.dart';
import 'package:legado_flutter/features/settings/backup_config_page.dart';
import 'package:legado_flutter/services/backup_service.dart';
import 'package:legado_flutter/services/book_progress_sync.dart';
import 'package:legado_flutter/services/bookmark_service.dart';
import 'package:legado_flutter/services/bookmark_sync_service.dart';
import 'package:legado_flutter/services/legacy_room_import_service_factory.dart';
import 'package:legado_flutter/services/webdav_prefs.dart';
import 'package:legado_flutter/services/webdav_setup_service.dart';

const _webDavUrl = String.fromEnvironment(
  'R5_WEBDAV_URL',
  defaultValue: 'http://10.0.2.2:19080/',
);
const _webDavUser = 'legado';
const _webDavPassword = 'legado-test';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('R5 Android WebDAV application smoke', (tester) async {
    await LegadoEngineBridge.tryInit();
    expect(
      LegadoEngineBridge.isAvailable,
      isTrue,
      reason: 'The Android integration test requires the Rust engine.',
    );

    final dbRoot = await Directory.systemTemp.createTemp('r5_webdav_db_');
    await LegadoDbBridge.init(dbPathOverride: '${dbRoot.path}/legado.db');
    expect(LegadoDbBridge.isReady, isTrue);

    final config = WebDavConfig(
      url: _webDavUrl,
      account: _webDavUser,
      password: _webDavPassword,
      dir: '/r5-android-${DateTime.now().millisecondsSinceEpoch}',
      device: 'R5 Android smoke',
    );
    await WebDavPrefs.save(config);

    const webdavRepository = FrbWebDavRepository();
    final backupService = BackupService(
      webdav: webdavRepository,
      backup: FrbBackupPort(),
    );
    final bookmarkSyncService = BookmarkSyncService(webdav: webdavRepository);
    final bookProgressSync = BookProgressSync(
      webdav: webdavRepository,
      store: await SharedPreferencesBookProgressSyncStore.load(),
    );

    // This uses the same repository path as application startup and settings.
    await WebDavSetupService.initialize(config, repository: webdavRepository);

    final localBookmark = BookmarkSnapshot(
      time: DateTime.now().millisecondsSinceEpoch,
      bookId: 'r5-webdav-book',
      bookName: 'R5 WebDAV Book',
      bookAuthor: 'R5 Author',
      chapterIndex: 2,
      chapterPos: 42,
      chapterName: 'Chapter 3',
      bookText: 'bookmark text',
      content: 'bookmark note',
    );
    expect(await bookmarkSyncService.uploadMerged(local: [localBookmark]), 1);

    List<BookmarkSnapshot>? mergedBookmarks;
    final mergedCount = await bookmarkSyncService.downloadAndMerge(
      local: const [],
      apply: (json) async {
        mergedBookmarks = BookmarkService.decodeJson(json);
      },
    );
    expect(mergedCount, 1);
    expect(mergedBookmarks, contains(localBookmark));

    final book = Book(
      id: 'r5-webdav-book',
      name: 'R5 WebDAV Book',
      author: 'R5 Author',
    );
    final progress = BookProgress(
      name: book.name,
      author: book.author,
      durChapterIndex: 2,
      durChapterPos: 42,
      durChapterTime: DateTime.now().millisecondsSinceEpoch,
      durChapterTitle: 'Chapter 3',
    );
    await bookProgressSync.uploadBookProgress(progress);
    final downloadedProgress = await bookProgressSync.getBookProgress(book);
    expect(downloadedProgress?.durChapterIndex, progress.durChapterIndex);
    expect(downloadedProgress?.durChapterPos, progress.durChapterPos);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BackupConfigPage(
            service: backupService,
            localFilePort: FileSystemBackupLocalFileAdapter(backupService),
            legacyRoomImportService: LegacyRoomImportServices.create(
              FrbLegacyRoomImportPort(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('上传到 WebDAV'), findsOneWidget);

    await tester.tap(find.text('上传到 WebDAV'));
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.text('已上传到 WebDAV'), findsOneWidget);

    final backups = await backupService.listWebDavBackups();
    expect(backups, isNotEmpty);

    // Keep the payload assertion tied to the production backup format.
    final json = await backupService.createFullBackupJson();
    expect(
      jsonDecode(json),
      containsPair('database', isA<Map<String, dynamic>>()),
    );
  });
}
