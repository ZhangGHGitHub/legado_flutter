import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../bridge/legado_db_bridge.dart';
import '../bridge/legado_engine_bridge.dart';
import '../services/app_paths.dart';
import '../src/rust/api/backup.dart' as backup_api;
import '../src/rust/api/webdav.dart' as webdav_api;
import 'settings_backup.dart';
import 'webdav_prefs.dart';

/// 备份与恢复服务（DB + 设置打包，支持本地/WebDAV）
class BackupService {
  BackupService();

  static const _archivePayloadName = 'legado_backup.json';

  void _requireReady() {
    if (!LegadoEngineBridge.isAvailable || !LegadoDbBridge.isReady) {
      throw StateError('Rust 引擎或数据库未就绪');
    }
  }

  String backupFileName({DateTime? now, String? device}) {
    final date = now ?? DateTime.now();
    final dateText =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    final normalizedDevice = _normalizeFileName(device?.trim() ?? '');
    return normalizedDevice.isEmpty
        ? 'backup$dateText.zip'
        : 'backup$dateText-$normalizedDevice.zip';
  }

  static Uint8List archiveJson(String json) {
    final archive = Archive()
      ..add(ArchiveFile.string(_archivePayloadName, json));
    return ZipEncoder().encodeBytes(archive);
  }

  static String extractJson(List<int> bytes) {
    if (!_isZip(bytes)) return utf8.decode(bytes);

    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final payload = archive.firstWhere(
        (entry) =>
            entry.isFile &&
            (entry.name == _archivePayloadName ||
                entry.name.toLowerCase().endsWith('.json')),
        orElse: () => throw const FormatException('ZIP 备份缺少 JSON 数据'),
      );
      return utf8.decode(payload.readBytes() ?? const <int>[]);
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('无法读取 ZIP 备份: $error');
    }
  }

  static bool _isZip(List<int> bytes) {
    return bytes.length >= 4 &&
        bytes[0] == 0x50 &&
        bytes[1] == 0x4b &&
        (bytes[2] == 0x03 || bytes[2] == 0x05 || bytes[2] == 0x07) &&
        (bytes[3] == 0x04 || bytes[3] == 0x06 || bytes[3] == 0x08);
  }

  static String _normalizeFileName(String value) {
    return value
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<String> createFullBackupJson() async {
    _requireReady();
    final database =
        jsonDecode(backup_api.exportBackup()) as Map<String, dynamic>;
    final settings = await SettingsBackup.collect();
    return const JsonEncoder.withIndent('  ').convert({
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'engineVersion': LegadoEngineBridge.engineVersion(),
      'database': database,
      'settings': settings,
    });
  }

  Future<File> backupToLocalFile() async {
    final json = await createFullBackupJson();
    final backupsDir = await AppPaths.backupsDir();
    final file = File(p.join(backupsDir.path, backupFileName()));
    await file.writeAsBytes(archiveJson(json));
    debugPrint('[Backup] 本地备份: ${file.path}');
    return file;
  }

  Future<void> restoreFromJson(String raw, {bool replace = true}) async {
    _requireReady();
    final root = jsonDecode(raw) as Map<String, dynamic>;
    final database = root['database'];
    if (database is! Map) {
      throw const FormatException('备份缺少 database 字段');
    }
    backup_api.restoreBackup(json: jsonEncode(database), replace: replace);
    final settings = root['settings'];
    if (settings is Map<String, dynamic>) {
      await SettingsBackup.apply(settings);
    }
  }

  Future<void> restoreFromBytes(List<int> bytes, {bool replace = true}) async {
    await restoreFromJson(extractJson(bytes), replace: replace);
  }

  Future<File?> pickAndRestore({bool replace = true}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip', 'json'],
    );
    if (result == null || result.files.single.path == null) return null;
    final file = File(result.files.single.path!);
    await restoreFromBytes(await file.readAsBytes(), replace: replace);
    return file;
  }

  Future<List<File>> listLocalBackups() async {
    final backupsDir = await AppPaths.backupsDir();
    if (!await backupsDir.exists()) return [];
    final files = await backupsDir
        .list()
        .where(
          (e) =>
              e is File &&
              (e.path.toLowerCase().endsWith('.zip') ||
                  e.path.toLowerCase().endsWith('.json')),
        )
        .cast<File>()
        .toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  String remoteBackupPath(WebDavConfig config, String filename) {
    return WebDavConfig.joinPath(config.rootDir, filename);
  }

  Future<void> backupToWebDav() async {
    final config = await WebDavPrefs.load();
    if (!config.isReady) {
      throw StateError('请先配置 WebDAV');
    }
    final json = await createFullBackupJson();
    final remote = remoteBackupPath(
      config,
      backupFileName(device: config.device),
    );
    await webdav_api.webdavUpload(
      url: config.url,
      username: config.account,
      password: config.password,
      remotePath: remote,
      data: archiveJson(json),
    );
    debugPrint('[Backup] WebDAV 上传: $remote');
  }

  Future<List<webdav_api.WebDavEntry>> listWebDavBackups() async {
    final config = await WebDavPrefs.load();
    if (!config.isReady) {
      throw StateError('请先配置 WebDAV');
    }
    final items = await webdav_api.webdavList(
      url: config.url,
      username: config.account,
      password: config.password,
      path: config.rootDir,
    );
    return items
        .where(
          (e) =>
              !e.isDir &&
              ((e.name.toLowerCase().startsWith('backup') &&
                      e.name.toLowerCase().endsWith('.zip')) ||
                  (e.name.toLowerCase().startsWith('legado_backup') &&
                      e.name.toLowerCase().endsWith('.json'))),
        )
        .toList()
      ..sort((a, b) => b.name.compareTo(a.name));
  }

  Future<void> restoreFromWebDav(
    String remotePath, {
    bool replace = true,
  }) async {
    final config = await WebDavPrefs.load();
    if (!config.isReady) {
      throw StateError('请先配置 WebDAV');
    }
    final bytes = await webdav_api.webdavDownload(
      url: config.url,
      username: config.account,
      password: config.password,
      remotePath: remotePath,
    );
    await restoreFromBytes(bytes, replace: replace);
  }

  Future<void> deleteWebDavBackup(String remotePath) async {
    final config = await WebDavPrefs.load();
    if (!config.isReady) {
      throw StateError('请先配置 WebDAV');
    }
    await webdav_api.webdavDelete(
      url: config.url,
      username: config.account,
      password: config.password,
      remotePath: remotePath,
    );
  }

  Future<void> renameWebDavBackup(String remotePath, String newName) async {
    final config = await WebDavPrefs.load();
    if (!config.isReady) {
      throw StateError('请先配置 WebDAV');
    }
    final name = newName.trim();
    if (name.isEmpty || name.contains('/') || name.contains('\\')) {
      throw const FormatException('备份名称不能为空且不能包含路径分隔符');
    }
    final directory = remotePath.substring(0, remotePath.lastIndexOf('/') + 1);
    final destination = '$directory$name';
    await webdav_api.webdavMove(
      url: config.url,
      username: config.account,
      password: config.password,
      remotePath: remotePath,
      destinationPath: destination,
    );
  }
}
