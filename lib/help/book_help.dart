import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../services/app_paths.dart';

/// 书籍缓存 — 对齐 Legado `BookHelp.kt`（章节正文文件缓存）
class BookHelp {
  BookHelp._();

  static Future<Directory> _cacheRoot() => AppPaths.bookCacheDir();

  static Future<File> _chapterFile(String bookId, String chapterId) async {
    final root = await _cacheRoot();
    final bookDir = Directory(p.join(root.path, _sanitize(bookId)));
    if (!await bookDir.exists()) {
      await bookDir.create(recursive: true);
    }
    return File(p.join(bookDir.path, '${_sanitize(chapterId)}.txt'));
  }

  static String _sanitize(String id) =>
      id.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

  /// 读取文件缓存的正文
  static Future<String?> getCachedContent(
    String bookId,
    String chapterId,
  ) async {
    try {
      final file = await _chapterFile(bookId, chapterId);
      if (!await file.exists()) return null;
      final text = await file.readAsString();
      return text.isEmpty ? null : text;
    } catch (e) {
      debugPrint('BookHelp 读取缓存失败: $e');
      return null;
    }
  }

  /// 写入文件缓存
  static Future<void> saveContent(
    String bookId,
    String chapterId,
    String content,
  ) async {
    if (content.isEmpty) return;
    try {
      final file = await _chapterFile(bookId, chapterId);
      await file.writeAsString(content, flush: true);
    } catch (e) {
      debugPrint('BookHelp 写入缓存失败: $e');
    }
  }

  /// 删除全部书籍缓存
  static Future<void> clearAllCache() async {
    try {
      final root = await _cacheRoot();
      if (await root.exists()) {
        await for (final entity in root.list()) {
          if (entity is Directory) {
            await entity.delete(recursive: true);
          } else if (entity is File) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('BookHelp 清除全部缓存失败: $e');
    }
  }

  /// 删除单本书的全部缓存
  static Future<void> clearBookCache(String bookId) async {
    try {
      final root = await _cacheRoot();
      final bookDir = Directory(p.join(root.path, _sanitize(bookId)));
      if (await bookDir.exists()) {
        await bookDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('BookHelp 清除缓存失败: $e');
    }
  }

  /// 删除数据库中已不存在的书籍缓存目录（对齐 legado clearInvalidCache）。
  static Future<int> clearInvalidCache(Set<String> validBookIds) async {
    var removed = 0;
    try {
      final root = await _cacheRoot();
      final valid = validBookIds.map(_sanitize).toSet();
      if (!await root.exists()) return 0;
      await for (final entity in root.list()) {
        if (entity is! Directory) continue;
        if (valid.contains(p.basename(entity.path))) continue;
        await entity.delete(recursive: true);
        removed++;
      }
    } catch (e) {
      debugPrint('BookHelp 清理孤立缓存失败: $e');
    }
    return removed;
  }

  /// 是否已有文件缓存
  static Future<bool> hasCachedContent(String bookId, String chapterId) async {
    final file = await _chapterFile(bookId, chapterId);
    return file.exists();
  }

  /// 列出某书已有正文文件缓存的章节 id（文件名已 sanitize）
  static Future<Set<String>> listCachedChapterIds(String bookId) async {
    try {
      final root = await _cacheRoot();
      final bookDir = Directory(p.join(root.path, _sanitize(bookId)));
      if (!await bookDir.exists()) return {};
      final ids = <String>{};
      await for (final entity in bookDir.list()) {
        if (entity is! File) continue;
        final name = p.basename(entity.path);
        if (!name.endsWith('.txt')) continue;
        // 文件名为 sanitize(chapterId).txt；调用方应用同规则比对
        ids.add(p.basenameWithoutExtension(name));
      }
      return ids;
    } catch (e) {
      debugPrint('BookHelp 列举缓存失败: $e');
      return {};
    }
  }

  /// 与 [_chapterFile] 相同的 id 规范化（供目录标记比对）
  static String sanitizeId(String id) => _sanitize(id);

  /// 已缓存正文字数（sanitize(chapterId) → 字符数，对齐目录「2974字」）
  static Future<Map<String, int>> mapCachedWordCounts(String bookId) async {
    try {
      final root = await _cacheRoot();
      final bookDir = Directory(p.join(root.path, _sanitize(bookId)));
      if (!await bookDir.exists()) return {};
      final counts = <String, int>{};
      await for (final entity in bookDir.list()) {
        if (entity is! File) continue;
        final name = p.basename(entity.path);
        if (!name.endsWith('.txt')) continue;
        try {
          final text = await entity.readAsString();
          if (text.isEmpty) continue;
          counts[p.basenameWithoutExtension(name)] = text.length;
        } catch (_) {
          // 单文件失败跳过
        }
      }
      return counts;
    } catch (e) {
      debugPrint('BookHelp 统计缓存字数失败: $e');
      return {};
    }
  }

  /// 单书缓存体积（字节）与章节文件数
  static Future<({int bytes, int chapterFiles})> bookCacheStats(
    String bookId,
  ) async {
    try {
      final root = await _cacheRoot();
      final bookDir = Directory(p.join(root.path, _sanitize(bookId)));
      if (!await bookDir.exists()) return (bytes: 0, chapterFiles: 0);
      var bytes = 0;
      var files = 0;
      await for (final entity in bookDir.list()) {
        if (entity is! File) continue;
        if (!entity.path.endsWith('.txt')) continue;
        try {
          bytes += await entity.length();
          files++;
        } catch (_) {}
      }
      return (bytes: bytes, chapterFiles: files);
    } catch (e) {
      debugPrint('BookHelp 统计缓存体积失败: $e');
      return (bytes: 0, chapterFiles: 0);
    }
  }

  /// 删除单章文件缓存（用于阅读器「刷新」）
  static Future<void> deleteChapterContent(
    String bookId,
    String chapterId,
  ) async {
    try {
      final file = await _chapterFile(bookId, chapterId);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('BookHelp 删除章节缓存失败: $e');
    }
  }
}
