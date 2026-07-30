import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/file_system/app_paths_port.dart';
import 'package:legado_flutter/domain/ports/backup_local_file_port.dart';
import 'package:legado_flutter/domain/ports/legacy_room_import_use_case.dart';
import 'package:legado_flutter/domain/remote/webdav_entry.dart';
import 'package:legado_flutter/domain/remote/legacy_room_import_report.dart';
import 'package:legado_flutter/features/settings/backup_config_page.dart';
import 'package:legado_flutter/application/preferences/shared_preferences_runtime.dart';
import 'package:legado_flutter/services/backup_service.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/sync_test_ports.dart';

BackupService _backupService() {
  return BackupService(
    webdav: const UnsupportedWebDavRepository(),
    backup: const UnavailableBackupPort(),
  );
}

class _FailingBackupService extends BackupService {
  _FailingBackupService({this.deleteError, this.restoreError})
    : super(
        webdav: const UnsupportedWebDavRepository(),
        backup: const UnavailableBackupPort(),
      );

  final Object? deleteError;
  final Object? restoreError;

  static const entry = WebDavEntry(
    name: 'backup2026-07-23.zip',
    path: '/legado/backup2026-07-23.zip',
    isDir: false,
    size: 128,
    lastModified: 0,
  );

  @override
  Future<List<WebDavEntry>> listWebDavBackups() async => [entry];

  @override
  Future<void> deleteWebDavBackup(String remotePath) async {
    throw deleteError!;
  }

  @override
  Future<void> restoreFromWebDav(
    String remotePath, {
    bool replace = true,
  }) async {
    throw restoreError!;
  }
}

class _FakeBackupLocalFilePort implements BackupLocalFilePort {
  _FakeBackupLocalFilePort(this.entries);

  final List<LocalBackupEntry> entries;

  @override
  bool get isAvailable => true;

  @override
  Future<List<LocalBackupEntry>> listBackups() async => entries;

  @override
  Future<List<int>> readBytes(LocalBackupEntry entry) async => [1, 2, 3];
}

class _FakeLegacyRoomImportUseCase implements LegacyRoomImportUseCase {
  @override
  LegacyRoomImportReport importDatabase({
    required String sourcePath,
    required String backupPath,
    bool replace = false,
  }) {
    return const LegacyRoomImportReport(
      sourceRoomVersion: 99,
      fingerprint: 'test',
      replaced: false,
      skippedDuplicate: false,
      backupWritten: true,
      counts: {},
      conflictCounts: {},
      preservedRows: {},
      warnings: [],
      unmappedColumns: {},
    );
  }
}

final _testLocalFilePort = _FakeBackupLocalFilePort(const []);
final _testLegacyRoomImport = _FakeLegacyRoomImportUseCase();
final _testAppPaths = _FakeAppPathsPort(Directory.systemTemp);

class _FakeAppPathsPort implements AppPathsPort {
  _FakeAppPathsPort(this.root);

  final Directory root;

  @override
  Future<Directory> dataRoot() async => root;

  @override
  Future<Directory> backupsDir() async =>
      Directory(p.join(root.path, 'backups'));
}

Future<void> _pumpWebDavPage(WidgetTester tester, BackupService service) async {
  SharedPreferences.setMockInitialValues({
    'webdav_url': 'https://dav.example.com/dav',
    'webdav_account': 'reader',
    'webdav_password': 'password',
  });
  SharedPreferencesRuntime.resetForTest();
  await tester.pumpWidget(
    Provider<AppPathsPort>.value(
      value: _testAppPaths,
      child: MaterialApp(
        home: Scaffold(
          body: BackupConfigPage(
            service: service,
            localFilePort: _testLocalFilePort,
            legacyRoomImportService: _testLegacyRoomImport,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('BackupConfigPage shows backup actions', (tester) async {
    await tester.pumpWidget(
      Provider<AppPathsPort>.value(
        value: _testAppPaths,
        child: MaterialApp(
          home: Scaffold(
            body: BackupConfigPage(
              service: _backupService(),
              localFilePort: _testLocalFilePort,
              legacyRoomImportService: _testLegacyRoomImport,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('一键本地备份'), findsOneWidget);
    expect(find.text('从文件恢复'), findsOneWidget);
    expect(find.text('上传到 WebDAV'), findsOneWidget);
    expect(find.text('从 WebDAV 恢复'), findsOneWidget);
    expect(find.text('WebDAV 备份'), findsOneWidget);
    expect(find.byTooltip('刷新 WebDAV 备份'), findsOneWidget);
  });

  testWidgets('local backup display uses the injected file port', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesRuntime.resetForTest();
    final port = _FakeBackupLocalFilePort([
      const LocalBackupEntry(
        name: 'backup2026-07-26.zip',
        path: r'C:\app\backups\backup2026-07-26.zip',
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BackupConfigPage(
            service: _backupService(),
            localFilePort: port,
            legacyRoomImportService: _testLegacyRoomImport,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('backup2026-07-26.zip'), findsOneWidget);
    expect(find.text(r'C:\app\backups\backup2026-07-26.zip'), findsOneWidget);
  });

  testWidgets('DELETE 405 tells the user the remote backup is still safe', (
    tester,
  ) async {
    await _pumpWebDavPage(
      tester,
      _FailingBackupService(
        deleteError: StateError('HTTP 405 Method Not Allowed'),
      ),
    );

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();

    expect(find.textContaining('原备份未删除'), findsOneWidget);
    expect(find.textContaining('启用 DELETE'), findsOneWidget);
  });

  testWidgets('restore permission failure says current data was not changed', (
    tester,
  ) async {
    await _pumpWebDavPage(
      tester,
      _FailingBackupService(restoreError: StateError('HTTP 403 Forbidden')),
    );

    await tester.tap(find.text('backup2026-07-23.zip'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '恢复'));
    await tester.pumpAndSettle();

    expect(find.textContaining('当前数据未修改'), findsOneWidget);
    expect(find.textContaining('读取权限'), findsOneWidget);
  });
}
