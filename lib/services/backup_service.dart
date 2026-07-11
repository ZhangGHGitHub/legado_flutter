import 'dart:convert';
import 'dart:io';

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

  void _requireReady() {
    if (!LegadoEngineBridge.isAvailable || !LegadoDbBridge.isReady) {
      throw StateError('Rust 引擎或数据库未就绪');
    }
  }

  String backupFileName() {
    final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
    return 'legado_backup_$ts.json';
  }

  Future<String> createFullBackupJson() async {
    _requireReady();
    final database = jsonDecode(backup_api.exportBackup()) as Map<String, dynamic>;
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
    await file.writeAsString(json);
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
    backup_api.restoreBackup(
      json: jsonEncode(database),
      replace: replace,
    );
    final settings = root['settings'];
    if (settings is Map<String, dynamic>) {
      await SettingsBackup.apply(settings);
    }
  }

  Future<File?> pickAndRestore({bool replace = true}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return null;
    final file = File(result.files.single.path!);
    final raw = await file.readAsString();
    await restoreFromJson(raw, replace: replace);
    return file;
  }

  Future<List<File>> listLocalBackups() async {
    final backupsDir = await AppPaths.backupsDir();
    if (!await backupsDir.exists()) return [];
    final files = await backupsDir
        .list()
        .where((e) => e is File && e.path.endsWith('.json'))
        .cast<File>()
        .toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  String _remotePath(WebDavConfig config, String filename) {
    final base = config.dir.endsWith('/') ? config.dir : '${config.dir}/';
    final device = config.device.trim().isEmpty ? 'Legado Flutter' : config.device.trim();
    return '$base$device/$filename'.replaceAll('//', '/');
  }

  Future<void> backupToWebDav() async {
    final config = await WebDavPrefs.load();
    if (!config.isConfigured) {
      throw StateError('请先配置 WebDAV');
    }
    final json = await createFullBackupJson();
    final remote = _remotePath(config, backupFileName());
    await webdav_api.webdavUpload(
      url: config.url,
      username: config.account,
      password: config.password,
      remotePath: remote,
      data: utf8.encode(json),
    );
    debugPrint('[Backup] WebDAV 上传: $remote');
  }

  Future<List<webdav_api.WebDavEntry>> listWebDavBackups() async {
    final config = await WebDavPrefs.load();
    if (!config.isConfigured) {
      throw StateError('请先配置 WebDAV');
    }
    final remoteDir = _remotePath(config, '').replaceAll(RegExp(r'/+$'), '');
    final items = await webdav_api.webdavList(
      url: config.url,
      username: config.account,
      password: config.password,
      path: remoteDir.isEmpty ? config.dir : remoteDir,
    );
    return items
        .where((e) => !e.isDir && e.name.endsWith('.json'))
        .toList()
      ..sort((a, b) => b.name.compareTo(a.name));
  }

  Future<void> restoreFromWebDav(String remotePath, {bool replace = true}) async {
    final config = await WebDavPrefs.load();
    if (!config.isConfigured) {
      throw StateError('请先配置 WebDAV');
    }
    final bytes = await webdav_api.webdavDownload(
      url: config.url,
      username: config.account,
      password: config.password,
      remotePath: remotePath,
    );
    await restoreFromJson(utf8.decode(bytes), replace: replace);
  }
}
