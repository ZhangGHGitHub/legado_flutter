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

  /// 是否已有文件缓存
  static Future<bool> hasCachedContent(String bookId, String chapterId) async {
    final file = await _chapterFile(bookId, chapterId);
    return file.exists();
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
