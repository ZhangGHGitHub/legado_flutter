import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/book.dart';
import '../models/book_progress.dart';
import '../src/rust/api/webdav.dart' as webdav_api;
import 'webdav_prefs.dart';

/// WebDAV 单书进度同步 — 对齐 Jingshiro `AppWebDav` bookProgress
class BookProgressSync {
  BookProgressSync._();

  static String _sanitizeFileName(String s) {
    return s.replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '_');
  }

  static String progressFileName(String name, String author) {
    return '${_sanitizeFileName('${name}_$author')}.json';
  }

  static String progressRemotePath(WebDavConfig config, String name, String author) {
    final base = config.dir.endsWith('/') ? config.dir : '${config.dir}/';
    return '$base${'bookProgress/'}${progressFileName(name, author)}'
        .replaceAll(RegExp(r'/{2,}'), '/');
  }

  static Future<bool> isConfigured() async {
    final c = await WebDavPrefs.load();
    return c.isConfigured;
  }

  static Future<BookProgress?> getBookProgress(Book book) async {
    final config = await WebDavPrefs.load();
    if (!config.isConfigured) return null;
    final remote = progressRemotePath(config, book.name, book.author);
    try {
      final bytes = await webdav_api.webdavDownload(
        url: config.url,
        username: config.account,
        password: config.password,
        remotePath: remote,
      );
      final json = utf8.decode(bytes);
      final map = jsonDecode(json);
      if (map is! Map<String, dynamic>) return null;
      return BookProgress.fromJson(map);
    } catch (e) {
      debugPrint('拉取阅读进度失败《${book.name}》: $e');
      return null;
    }
  }

  static Future<void> uploadBookProgress(
    BookProgress progress, {
    bool toast = false,
  }) async {
    final config = await WebDavPrefs.load();
    if (!config.isConfigured) {
      throw StateError('请先配置 WebDAV');
    }
    final remote = progressRemotePath(config, progress.name, progress.author);
    final data = utf8.encode(jsonEncode(progress.toJson()));
    await webdav_api.webdavUpload(
      url: config.url,
      username: config.account,
      password: config.password,
      remotePath: remote,
      data: data,
    );
    debugPrint('上传进度成功: $remote toast=$toast');
  }
}
