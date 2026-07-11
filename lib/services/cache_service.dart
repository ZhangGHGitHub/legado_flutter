import 'dart:io';

import 'package:flutter/foundation.dart';

import '../bridge/legado_engine_bridge.dart';
import '../src/rust/api/network.dart' as network_api;
import 'app_paths.dart';

/// 缓存统计与清理（Phase 4.3）
class CacheStats {
  final int bookCacheBytes;
  final int dbBytes;
  final int backupsBytes;

  const CacheStats({
    required this.bookCacheBytes,
    required this.dbBytes,
    required this.backupsBytes,
  });

  int get totalBytes => bookCacheBytes + dbBytes + backupsBytes;

  String get totalLabel => _formatBytes(totalBytes);
  String get bookCacheLabel => _formatBytes(bookCacheBytes);
  String get dbLabel => _formatBytes(dbBytes);
  String get backupsLabel => _formatBytes(backupsBytes);

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class CacheService {
  Future<int> _dirSize(Directory dir) async {
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        try {
          total += await entity.length();
        } catch (_) {}
      }
    }
    return total;
  }

  Future<int> _fileSize(String path) async {
    final file = File(path);
    if (!await file.exists()) return 0;
    return file.length();
  }

  Future<CacheStats> loadStats() async {
    final cacheDir = await AppPaths.bookCacheDir();
    final backupsDir = await AppPaths.backupsDir();
    final dbPath = await AppPaths.dbPath();
    return CacheStats(
      bookCacheBytes: await _dirSize(cacheDir),
      dbBytes: await _fileSize(dbPath),
      backupsBytes: await _dirSize(backupsDir),
    );
  }

  Future<void> clearBookCache() async {
    final dir = await AppPaths.bookCacheDir();
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        if (entity is Directory) {
          await entity.delete(recursive: true);
        } else if (entity is File) {
          await entity.delete();
        }
      }
    }
    debugPrint('[Cache] 已清空书籍缓存');
  }

  Future<void> clearEngineCache() async {
    if (LegadoEngineBridge.isAvailable) {
      network_api.clearEngineCache();
    }
    debugPrint('[Cache] 已清空引擎 Cookie/JS 缓存');
  }

  Future<void> clearBackups() async {
    final dir = await AppPaths.backupsDir();
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        await entity.delete(recursive: true);
      }
    }
    debugPrint('[Cache] 已清空本地备份');
  }

  Future<void> clearAll() async {
    await clearBookCache();
    await clearEngineCache();
  }
}
