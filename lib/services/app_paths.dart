import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../application/preferences/shared_preferences_runtime.dart';

/// 数据目录与路径（Phase 4.3）
abstract final class AppDataPrefs {
  static const dataDirKey = 'legado_data_dir';

  static Future<String?> loadDataDir() async {
    final prefs = await SharedPreferencesRuntime.getOrNull();
    final raw = prefs?.getString(dataDirKey);
    if (raw == null || raw.trim().isEmpty) return null;
    return raw.trim();
  }

  static Future<void> saveDataDir(String? path) async {
    final prefs = await SharedPreferencesRuntime.getOrNull();
    if (prefs == null) return;
    if (path == null || path.trim().isEmpty) {
      await prefs.remove(dataDirKey);
      return;
    }
    await prefs.setString(dataDirKey, path.trim());
  }
}

abstract final class AppPaths {
  static const bookCacheFolder = 'book_cache';
  static const backupsFolder = 'backups';
  static const dbFileName = 'legado.db';

  /// 应用数据根目录（可自定义，默认 ApplicationSupport）
  static Future<Directory> dataRoot() async {
    final override = await AppDataPrefs.loadDataDir();
    if (override != null) {
      final dir = Directory(override);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }
    return getApplicationSupportDirectory();
  }

  static Future<String> dbPath() async {
    final root = await dataRoot();
    return p.join(root.path, dbFileName);
  }

  static Future<Directory> bookCacheDir() async {
    final root = await dataRoot();
    final dir = Directory(p.join(root.path, bookCacheFolder));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<Directory> backupsDir() async {
    final root = await dataRoot();
    final dir = Directory(p.join(root.path, backupsFolder));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
