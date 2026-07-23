import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/book.dart';
import '../models/book_progress.dart';
import '../src/rust/api/webdav.dart' as webdav_api;
import 'webdav_prefs.dart';

typedef WebDavListInvoker =
    Future<List<webdav_api.WebDavEntry>> Function({
      required String url,
      required String username,
      required String password,
      required String path,
    });

typedef WebDavDownloadInvoker =
    Future<Uint8List> Function({
      required String url,
      required String username,
      required String password,
      required String remotePath,
    });

typedef WebDavUploadInvoker =
    Future<void> Function({
      required String url,
      required String username,
      required String password,
      required String remotePath,
      required List<int> data,
    });

enum BookProgressSyncDecision { skipUnchangedRemote, keepLocal, applyRemote }

/// WebDAV 单书进度同步 — 对齐 Jingshiro `AppWebDav` bookProgress
class BookProgressSync {
  BookProgressSync._();

  static String syncTimeKey(String name, String author) {
    return 'webdav_book_progress_sync_${progressFileName(name, author)}';
  }

  static String _sanitizeFileName(String s) {
    return s.replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '_');
  }

  static String progressFileName(String name, String author) {
    return '${_sanitizeFileName('${name}_$author')}.json';
  }

  static String progressRemotePath(
    WebDavConfig config,
    String name,
    String author,
  ) {
    final base = config.dir.endsWith('/') ? config.dir : '${config.dir}/';
    return '$base${'bookProgress/'}${progressFileName(name, author)}'
        .replaceAll(RegExp(r'/{2,}'), '/');
  }

  static String progressDirectoryPath(WebDavConfig config) {
    final base = config.dir.endsWith('/') ? config.dir : '${config.dir}/';
    return '$base${'bookProgress/'}'.replaceAll(RegExp(r'/{2,}'), '/');
  }

  static Future<int> loadSyncTime(String name, String author) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(syncTimeKey(name, author)) ?? 0;
  }

  static Future<void> saveSyncTime(
    String name,
    String author, {
    required int syncTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(syncTimeKey(name, author), syncTime);
  }

  static BookProgressSyncDecision decideRemoteProgress({
    required BookProgress remote,
    required int remoteLastModified,
    required int localSyncTime,
    required int localChapterIndex,
    required int localChapterPos,
  }) {
    // AppWebDav checks the file timestamp before reading/merging its JSON.
    if (remoteLastModified <= localSyncTime) {
      return BookProgressSyncDecision.skipUnchangedRemote;
    }
    if (remote.isAheadOf(
      chapterIndex: localChapterIndex,
      chapterPos: localChapterPos,
    )) {
      return BookProgressSyncDecision.applyRemote;
    }
    return BookProgressSyncDecision.keepLocal;
  }

  static Future<bool> isConfigured() async {
    final c = await WebDavPrefs.load();
    return c.isReady;
  }

  static Future<BookProgress?> getBookProgress(Book book) async {
    final config = await WebDavPrefs.load();
    if (!config.isReady) return null;
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

  static Future<int> downloadAllBookProgress({
    required Iterable<Book> books,
    required Future<void> Function(Book book, BookProgress progress) apply,
    WebDavListInvoker list = webdav_api.webdavList,
    WebDavDownloadInvoker download = webdav_api.webdavDownload,
    int Function()? nowMillis,
  }) async {
    final config = await WebDavPrefs.load();
    if (!config.isReady) return 0;

    final entries = await list(
      url: config.url,
      username: config.account,
      password: config.password,
      path: progressDirectoryPath(config),
    );
    final files = <String, webdav_api.WebDavEntry>{
      for (final entry in entries)
        if (!entry.isDir) entry.name: entry,
    };
    var appliedCount = 0;
    for (final book in books) {
      final fileName = progressFileName(book.name, book.author);
      final entry = files[fileName];
      if (entry == null) continue;

      final localSyncTime = await loadSyncTime(book.name, book.author);
      if (entry.lastModified <= localSyncTime) continue;

      try {
        final bytes = await download(
          url: config.url,
          username: config.account,
          password: config.password,
          remotePath: progressRemotePath(config, book.name, book.author),
        );
        final value = jsonDecode(utf8.decode(bytes));
        if (value is! Map<String, dynamic>) continue;
        final remote = BookProgress.fromJson(value);
        final decision = decideRemoteProgress(
          remote: remote,
          remoteLastModified: entry.lastModified,
          localSyncTime: localSyncTime,
          localChapterIndex: book.durChapterIndex,
          localChapterPos: book.currentPageIndex,
        );
        if (decision != BookProgressSyncDecision.applyRemote) continue;

        await apply(book, remote);
        await saveSyncTime(
          book.name,
          book.author,
          syncTime: nowMillis?.call() ?? DateTime.now().millisecondsSinceEpoch,
        );
        appliedCount++;
      } catch (e) {
        debugPrint('批量拉取阅读进度失败《${book.name}》: $e');
      }
    }
    return appliedCount;
  }

  static Future<void> uploadBookProgress(
    BookProgress progress, {
    bool toast = false,
    WebDavUploadInvoker upload = webdav_api.webdavUpload,
    int Function()? nowMillis,
  }) async {
    await AppConfig.instance.load();
    if (!AppConfig.instance.syncBookProgress) return;
    final config = await WebDavPrefs.load();
    if (!config.isReady) {
      throw StateError('请先配置 WebDAV');
    }
    final remote = progressRemotePath(config, progress.name, progress.author);
    final data = utf8.encode(jsonEncode(progress.toJson()));
    await upload(
      url: config.url,
      username: config.account,
      password: config.password,
      remotePath: remote,
      data: data,
    );
    await saveSyncTime(
      progress.name,
      progress.author,
      syncTime: nowMillis?.call() ?? DateTime.now().millisecondsSinceEpoch,
    );
    debugPrint('上传进度成功: $remote toast=$toast');
  }
}
