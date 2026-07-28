import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../domain/ports/book_progress_sync_store.dart';
import '../domain/ports/webdav_repository.dart';
import '../domain/remote/webdav_entry.dart';
import '../infrastructure/preferences/shared_preferences_book_progress_sync_store.dart';
import '../infrastructure/webdav/frb_webdav_repository.dart';
import '../models/book.dart';
import '../models/book_progress.dart';
import 'webdav_prefs.dart';
import 'sync_conflict_policy.dart';

typedef WebDavListInvoker =
    Future<List<WebDavEntry>> Function({
      required String url,
      required String username,
      required String password,
      required String path,
    });

typedef WebDavDownloadInvoker =
    Future<List<int>> Function({
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

typedef WebDavEtagReader =
    Future<String?> Function({
      required String url,
      required String username,
      required String password,
      required String remotePath,
    });

typedef WebDavUploadIfMatchInvoker =
    Future<void> Function({
      required String url,
      required String username,
      required String password,
      required String remotePath,
      required List<int> data,
      String? etag,
    });

enum BookProgressSyncDecision { skipUnchangedRemote, keepLocal, applyRemote }

/// WebDAV 单书进度同步 — 对齐 Jingshiro `AppWebDav` bookProgress
class BookProgressSync {
  BookProgressSync._();

  static const WebDavRepository _webdav = FrbWebDavRepository();

  static const _maxConditionalUploadRetries = 1;

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

  static Future<String?> _readRemoteEtag({
    required String url,
    required String username,
    required String password,
    required String remotePath,
  }) async {
    final directory = remotePath.substring(0, remotePath.lastIndexOf('/') + 1);
    final fileName = remotePath.substring(remotePath.lastIndexOf('/') + 1);
    final entries = await _webdav.list(
      url: url,
      username: username,
      password: password,
      path: directory,
    );
    for (final entry in entries) {
      if (!entry.isDir &&
          (entry.name == fileName || entry.path == remotePath)) {
        return entry.etag;
      }
    }
    return null;
  }

  static bool _isPreconditionFailed(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('412') || message.contains('precondition failed');
  }

  static Future<int> loadSyncTime(
    String name,
    String author, {
    BookProgressSyncStore? store,
  }) async {
    final syncStore = await _resolveStore(store);
    return await syncStore.read(syncTimeKey(name, author)) ?? 0;
  }

  static Future<void> saveSyncTime(
    String name,
    String author, {
    required int syncTime,
    BookProgressSyncStore? store,
  }) async {
    final syncStore = await _resolveStore(store);
    await syncStore.write(syncTimeKey(name, author), syncTime);
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

  /// Exposes the four-way cross-device decision without changing the legacy
  /// remote-position behavior used by the existing download path.
  static SyncConflictResult decideConflict({
    required BookProgress local,
    required BookProgress remote,
    required int baseRevision,
  }) {
    return SyncConflictPolicy.compareBookProgress(
      local: local,
      remote: remote,
      baseRevision: baseRevision,
    );
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
      final bytes = await _webdav.download(
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
    WebDavListInvoker list = _defaultList,
    WebDavDownloadInvoker download = _defaultDownload,
    int Function()? nowMillis,
    BookProgressSyncStore? store,
  }) async {
    final config = await WebDavPrefs.load();
    if (!config.isReady) return 0;
    final syncStore = await _resolveStore(store);

    final entries = await list(
      url: config.url,
      username: config.account,
      password: config.password,
      path: progressDirectoryPath(config),
    );
    final files = <String, WebDavEntry>{
      for (final entry in entries)
        if (!entry.isDir) entry.name: entry,
    };
    var appliedCount = 0;
    for (final book in books) {
      final fileName = progressFileName(book.name, book.author);
      final entry = files[fileName];
      if (entry == null) continue;

      final localSyncTime = await loadSyncTime(
        book.name,
        book.author,
        store: syncStore,
      );
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
          store: syncStore,
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
    WebDavUploadInvoker? upload,
    WebDavEtagReader readEtag = _readRemoteEtag,
    WebDavUploadIfMatchInvoker uploadIfMatch = _defaultUploadIfMatch,
    int Function()? nowMillis,
    BookProgressSyncStore? store,
  }) async {
    await AppConfig.instance.load();
    if (!AppConfig.instance.syncBookProgress) return;
    final config = await WebDavPrefs.load();
    if (!config.isReady) {
      throw StateError('请先配置 WebDAV');
    }
    final syncStore = await _resolveStore(store);
    final remote = progressRemotePath(config, progress.name, progress.author);
    final data = utf8.encode(jsonEncode(progress.toJson()));
    if (upload != null) {
      await upload(
        url: config.url,
        username: config.account,
        password: config.password,
        remotePath: remote,
        data: data,
      );
    } else {
      var etag = await readEtag(
        url: config.url,
        username: config.account,
        password: config.password,
        remotePath: remote,
      );
      var retryCount = 0;
      while (true) {
        try {
          await uploadIfMatch(
            url: config.url,
            username: config.account,
            password: config.password,
            remotePath: remote,
            data: data,
            etag: etag,
          );
          break;
        } catch (error) {
          if (!_isPreconditionFailed(error) ||
              retryCount >= _maxConditionalUploadRetries) {
            rethrow;
          }
          retryCount++;
          etag = await readEtag(
            url: config.url,
            username: config.account,
            password: config.password,
            remotePath: remote,
          );
        }
      }
    }
    await saveSyncTime(
      progress.name,
      progress.author,
      syncTime: nowMillis?.call() ?? DateTime.now().millisecondsSinceEpoch,
      store: syncStore,
    );
    debugPrint('上传进度成功: $remote toast=$toast');
  }

  static Future<BookProgressSyncStore> _resolveStore(
    BookProgressSyncStore? store,
  ) async {
    return store ?? await SharedPreferencesBookProgressSyncStore.load();
  }

  static Future<List<WebDavEntry>> _defaultList({
    required String url,
    required String username,
    required String password,
    required String path,
  }) {
    return _webdav.list(
      url: url,
      username: username,
      password: password,
      path: path,
    );
  }

  static Future<List<int>> _defaultDownload({
    required String url,
    required String username,
    required String password,
    required String remotePath,
  }) {
    return _webdav.download(
      url: url,
      username: username,
      password: password,
      remotePath: remotePath,
    );
  }

  static Future<void> _defaultUploadIfMatch({
    required String url,
    required String username,
    required String password,
    required String remotePath,
    required List<int> data,
    String? etag,
  }) {
    return _webdav.uploadIfMatch(
      url: url,
      username: username,
      password: password,
      remotePath: remotePath,
      data: data,
      etag: etag,
    );
  }
}
