import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/pages/config/backup_config_page.dart';
import 'package:legado_flutter/services/backup_service.dart';
import 'package:legado_flutter/src/rust/api/webdav.dart' as webdav_api;
import 'package:shared_preferences/shared_preferences.dart';

class _FailingBackupService extends BackupService {
  _FailingBackupService({this.deleteError, this.restoreError});

  final Object? deleteError;
  final Object? restoreError;

  static const entry = webdav_api.WebDavEntry(
    name: 'backup2026-07-23.zip',
    path: '/legado/backup2026-07-23.zip',
    isDir: false,
    size: 128,
    lastModified: 0,
  );

  @override
  Future<List<webdav_api.WebDavEntry>> listWebDavBackups() async => [entry];

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

Future<void> _pumpWebDavPage(WidgetTester tester, BackupService service) async {
  SharedPreferences.setMockInitialValues({
    'webdav_url': 'https://dav.example.com/dav',
    'webdav_account': 'reader',
    'webdav_password': 'password',
  });
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: BackupConfigPage(service: service)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('BackupConfigPage shows backup actions', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: BackupConfigPage())),
    );
    await tester.pump();

    expect(find.text('一键本地备份'), findsOneWidget);
    expect(find.text('从文件恢复'), findsOneWidget);
    expect(find.text('上传到 WebDAV'), findsOneWidget);
    expect(find.text('从 WebDAV 恢复'), findsOneWidget);
    expect(find.text('WebDAV 备份'), findsOneWidget);
    expect(find.byTooltip('刷新 WebDAV 备份'), findsOneWidget);
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
