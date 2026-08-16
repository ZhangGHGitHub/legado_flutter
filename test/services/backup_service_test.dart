import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/bridge/legado_db_bridge.dart';
import 'package:legado_flutter/bridge/legado_engine_bridge.dart';
import 'package:legado_flutter/domain/ports/backup_port.dart';
import 'package:legado_flutter/infrastructure/database/frb_backup_port.dart';
import 'package:legado_flutter/application/preferences/shared_preferences_runtime.dart';
import 'package:legado_flutter/services/backup_service.dart';
import 'package:legado_flutter/services/webdav_prefs.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/sync_test_ports.dart';

BackupService _service({BackupPort backup = const UnavailableBackupPort()}) {
  return BackupService(
    webdav: const UnsupportedWebDavRepository(),
    backup: backup,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({'legado_theme_mode': 'light'});

  test('BackupService follows the original cloud backup filename format', () {
    final service = _service();
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

  test('BackupService emits the original app JSON file subset', () {
    final raw = jsonEncode({
      'version': 1,
      'database': {
        'books': [
          {
            'id': 'book-1',
            'name': '测试书',
            'author': '作者',
            'bookSourceUrl': 'https://source.test',
            'totalChapterNum': 10,
            'durChapterIndex': 3,
          },
        ],
        'sources': [
          {'bookSourceUrl': 'https://source.test', 'bookSourceName': '测试源'},
        ],
        'bookmarks': [
          {'time': 1, 'bookName': '测试书', 'bookAuthor': '作者'},
        ],
        'replaceRules': [
          {'id': '7', 'pattern': '旧', 'replacement': '新'},
        ],
        'detailedReadRecords': [
          {
            'bookName': '测试书',
            'sessions': [
              {'startTime': 1, 'endTime': 2, 'readIteration': 0},
            ],
          },
        ],
      },
    });

    final archive = ZipDecoder().decodeBytes(BackupService.archiveJson(raw));
    final names = archive.map((entry) => entry.name).toSet();
    expect(
      names,
      containsAll([
        'legado_backup.json',
        'bookshelf.json',
        'bookmark.json',
        'bookSource.json',
        'replaceRule.json',
        'readRecord_detail.json',
      ]),
    );

    final bookshelf = archive.firstWhere(
      (entry) => entry.name == 'bookshelf.json',
    );
    final book =
        (jsonDecode(utf8.decode(bookshelf.readBytes()!)) as List).single;
    expect(book['bookUrl'], 'book-1');
    expect(book['origin'], 'https://source.test');
    expect(book['durChapterIndex'], 3);

    final rule = archive.firstWhere(
      (entry) => entry.name == 'replaceRule.json',
    );
    expect(
      (jsonDecode(utf8.decode(rule.readBytes()!)) as List).single['id'],
      7,
    );
  });

  test('BackupService reads original app JSON files into the Rust wrapper', () {
    final archive = Archive()
      ..add(
        ArchiveFile.string(
          'backup/bookshelf.json',
          jsonEncode([
            {
              'bookUrl': 'book-1',
              'name': '测试书',
              'author': '作者',
              'origin': 'https://source.test',
              'totalChapterNum': 10,
              'durChapterIndex': 3,
              'durChapterPos': 12,
            },
          ]),
        ),
      )
      ..add(
        ArchiveFile.string(
          'backup/bookSource.json',
          jsonEncode([
            {'bookSourceUrl': 'https://source.test', 'bookSourceName': '测试源'},
          ]),
        ),
      )
      ..add(
        ArchiveFile.string(
          'backup/bookmark.json',
          jsonEncode([
            {
              'time': 1,
              'bookName': '测试书',
              'bookAuthor': '作者',
              'chapterIndex': 3,
              'chapterPos': 12,
            },
          ]),
        ),
      );

    final root =
        jsonDecode(BackupService.extractJson(ZipEncoder().encodeBytes(archive)))
            as Map<String, dynamic>;
    final database = root['database'] as Map<String, dynamic>;
    expect((database['books'] as List).single['id'], 'book-1');
    expect((database['books'] as List).single['currentPageIndex'], 12);
    expect(
      (database['sources'] as List).single['bookSourceUrl'],
      'https://source.test',
    );
    expect((database['bookmarks'] as List).single['bookId'], '');
  });

  test(
    'BackupService uploads cloud backups directly under the WebDAV root',
    () {
      const config = WebDavConfig(dir: '/legado', device: 'Pixel One');

      expect(
        _service().remoteBackupPath(config, 'backup2026-07-23-Pixel One.zip'),
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

    final service = _service(backup: FrbBackupPort());
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
    SharedPreferencesRuntime.resetForTest();

    await expectLater(
      _service().backupToWebDav(),
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
    SharedPreferencesRuntime.resetForTest();

    await expectLater(
      _service().renameWebDavBackup('/legado/device/backup.json', '../x'),
      throwsA(isA<FormatException>()),
    );
  });
}
