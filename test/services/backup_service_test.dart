import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/bridge/legado_db_bridge.dart';
import 'package:legado_flutter/bridge/legado_engine_bridge.dart';
import 'package:legado_flutter/services/backup_service.dart';
import 'package:legado_flutter/services/webdav_prefs.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({'legado_theme_mode': 'light'});

  test('BackupService follows the original cloud backup filename format', () {
    final service = BackupService();
    final date = DateTime(2026, 7, 23, 18, 30);

    expect(service.backupFileName(now: date), 'backup2026-07-23.zip');
    expect(
      service.backupFileName(now: date, device: 'Pixel/One'),
      'backup2026-07-23-Pixel_One.zip',
    );
  });

  test('BackupService creates and reads a ZIP backup payload', () {
    const raw = '{"version":1,"database":{"books":[]}}';
    final bytes = BackupService.archiveJson(raw);
    final archive = ZipDecoder().decodeBytes(bytes);

    expect(archive.map((entry) => entry.name), contains('legado_backup.json'));
    expect(BackupService.extractJson(bytes), raw);
  });

  test(
    'BackupService uploads cloud backups directly under the WebDAV root',
    () {
      const config = WebDavConfig(dir: '/legado', device: 'Pixel One');

      expect(
        BackupService().remoteBackupPath(
          config,
          'backup2026-07-23-Pixel One.zip',
        ),
        '/legado/backup2026-07-23-Pixel One.zip',
      );
    },
  );

  test('BackupService keeps legacy JSON restore payloads readable', () {
    const raw = '{"version":1,"database":{"books":[]}}';
    expect(BackupService.extractJson(raw.codeUnits), raw);
  });

  test('BackupService creates full backup JSON when engine ready', () async {
    await LegadoEngineBridge.tryInit();
    if (!LegadoEngineBridge.isAvailable) return;

    final tempDir = await Directory.systemTemp.createTemp(
      'legado_backup_test_',
    );
    await LegadoDbBridge.init(
      dbPathOverride: p.join(tempDir.path, 'legado.db'),
    );

    final service = BackupService();
    final raw = await service.createFullBackupJson();
    final map = jsonDecode(raw) as Map<String, dynamic>;
    expect(map['version'], 1);
    expect(map['database'], isA<Map>());
    expect(map['settings'], isA<Map>());
    expect((map['database'] as Map)['books'], isA<List>());
  });

  test('BackupService WebDAV actions require complete credentials', () async {
    SharedPreferences.setMockInitialValues({
      'webdav_url': 'https://dav.example.com/dav',
    });

    await expectLater(
      BackupService().backupToWebDav(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          '请先配置 WebDAV',
        ),
      ),
    );
  });

  test('BackupService rejects unsafe WebDAV backup names', () async {
    SharedPreferences.setMockInitialValues({
      'webdav_url': 'https://dav.example.com/dav',
      'webdav_account': 'account',
      'webdav_password': 'password',
    });

    await expectLater(
      BackupService().renameWebDavBackup('/legado/device/backup.json', '../x'),
      throwsA(isA<FormatException>()),
    );
  });
}
