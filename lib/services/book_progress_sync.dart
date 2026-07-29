import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../domain/ports/book_progress_sync_store.dart';
import '../domain/ports/webdav_repository.dart';
import '../domain/remote/webdav_entry.dart';
import 'package:legado_flutter/domain/book/book.dart';
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
  const BookProgressSync({
    required WebDavRepository webdav,
    required BookProgressSyncStore store,
  }) : _webdav = webdav,
       _store = store;

  final WebDavRepository _webdav;
  final BookProgressSyncStore _store;

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

  Future<String?> _readRemoteEtag({
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

  Future<int> loadSyncTime(String name, String author) async {
    return await _store.read(syncTimeKey(name, author)) ?? 0;
  }

  Future<void> saveSyncTime(
    String name,
    String author, {
    required int syncTime,
  }) async {
    await _store.write(syncTimeKey(name, author), syncTime);
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

  Future<bool> isConfigured() async {
    final c = await WebDavPrefs.load();
    return c.isReady;
  }

  Future<BookProgress?> getBookProgress(Book book) async {
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

  Future<int> downloadAllBookProgress({
    required Iterable<Book> books,
    required Future<void> Function(Book book, BookProgress progress) apply,
    WebDavListInvoker? list,
    WebDavDownloadInvoker? download,
    int Function()? nowMillis,
  }) async {
    final config = await WebDavPrefs.load();
    if (!config.isReady) return 0;
    final effectiveList = list ?? _defaultList;
    final effectiveDownload = download ?? _defaultDownload;

    final entries = await effectiveList(
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

      final localSyncTime = await loadSyncTime(book.name, book.author);
      if (entry.lastModified <= localSyncTime) continue;

      try {
        final bytes = await effectiveDownload(
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

  Future<void> uploadBookProgress(
    BookProgress progress, {
    bool toast = false,
    WebDavUploadInvoker? upload,
    WebDavEtagReader? readEtag,
    WebDavUploadIfMatchInvoker? uploadIfMatch,
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
    if (upload != null) {
      await upload(
        url: config.url,
        username: config.account,
        password: config.password,
        remotePath: remote,
        data: data,
      );
    } else {
      final effectiveReadEtag = readEtag ?? _readRemoteEtag;
      final effectiveUploadIfMatch = uploadIfMatch ?? _defaultUploadIfMatch;
      var etag = await effectiveReadEtag(
        url: config.url,
        username: config.account,
        password: config.password,
        remotePath: remote,
      );
      var retryCount = 0;
      while (true) {
        try {
          await effectiveUploadIfMatch(
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
          etag = await effectiveReadEtag(
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
    );
    debugPrint('上传进度成功: $remote toast=$toast');
  }

  Future<List<WebDavEntry>> _defaultList({
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

  Future<List<int>> _defaultDownload({
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

  Future<void> _defaultUploadIfMatch({
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
