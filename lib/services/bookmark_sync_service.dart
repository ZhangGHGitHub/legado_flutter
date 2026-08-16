import 'dart:async';
import 'dart:convert';

import '../domain/annotation/bookmark_snapshot.dart';
import '../domain/ports/webdav_repository.dart';
import '../domain/remote/webdav_entry.dart';
import 'bookmark_service.dart';
import 'webdav_prefs.dart';

typedef BookmarkWebDavDownloadInvoker =
    Future<List<int>> Function({
      required String url,
      required String username,
      required String password,
      required String remotePath,
    });

typedef BookmarkWebDavUploadInvoker =
    Future<void> Function({
      required String url,
      required String username,
      required String password,
      required String remotePath,
      required List<int> data,
    });

typedef BookmarkWebDavListInvoker =
    Future<List<WebDavEntry>> Function({
      required String url,
      required String username,
      required String password,
      required String path,
    });

typedef BookmarkWebDavConditionalUploadInvoker =
    Future<void> Function({
      required String url,
      required String username,
      required String password,
      required String remotePath,
      required List<int> data,
      String? etag,
    });

/// WebDAV bookmark.json 同步；合并策略由 BookmarkService 统一定义。
class BookmarkSyncService {
  BookmarkSyncService({required WebDavRepository webdav}) : _webdav = webdav;

  final WebDavRepository _webdav;

  // Keep the full read/merge/write operation ordered within this app process.
  static Future<void> _syncTail = Future<void>.value();

  static String remotePath(WebDavConfig config) {
    final base = config.dir.endsWith('/') ? config.dir : '${config.dir}/';
    return '${base}bookmark.json'.replaceAll(RegExp(r'/{2,}'), '/');
  }

  Future<int> uploadMerged({
    required Iterable<BookmarkSnapshot> local,
    BookmarkWebDavDownloadInvoker? download,
    BookmarkWebDavUploadInvoker? upload,
    BookmarkWebDavListInvoker? list,
    BookmarkWebDavConditionalUploadInvoker? uploadIfMatch,
    int maxConflictRetries = 2,
  }) async {
    return _withSyncLock(() async {
      if (maxConflictRetries < 0) {
        throw RangeError.value(
          maxConflictRetries,
          'maxConflictRetries',
          'must be non-negative',
        );
      }
      final config = await _readyConfig();
      final localItems = local.toList(growable: false);
      final effectiveDownload = download ?? _defaultDownload;
      final effectiveUpload = upload ?? _defaultUpload;
      final etagList = list ?? (upload == null ? _defaultList : null);
      final conditionalUpload =
          uploadIfMatch ?? (upload == null ? _defaultUploadIfMatch : null);
      var remote = await _readRemote(
        config: config,
        download: effectiveDownload,
        list: etagList,
      );
      var merged = _merge(localItems, remote);
      var conflictRetries = 0;

      while (true) {
        final data = utf8.encode(BookmarkService.encodeJson(merged));
        if (conditionalUpload != null &&
            remote?.etagKnown == true &&
            remote?.exists == true &&
            remote?.etag == null) {
          throw StateError('无法确认 bookmark.json 的最新 ETag，已停止覆盖上传');
        }
        if (conditionalUpload == null || remote?.etagKnown == false) {
          await effectiveUpload(
            url: config.url,
            username: config.account,
            password: config.password,
            remotePath: remotePath(config),
            data: data,
          );
          return merged.length;
        }

        try {
          await conditionalUpload(
            url: config.url,
            username: config.account,
            password: config.password,
            remotePath: remotePath(config),
            data: data,
            etag: remote?.etag,
          );
          return merged.length;
        } catch (error) {
          if (!_isPreconditionFailed(error) ||
              conflictRetries >= maxConflictRetries) {
            rethrow;
          }
          conflictRetries++;
          remote = await _readRemote(
            config: config,
            download: effectiveDownload,
            list: etagList,
          );
          if (remote?.etagKnown != true) {
            throw StateError('无法确认 bookmark.json 的最新 ETag，已停止覆盖上传');
          }
          merged = _merge(localItems, remote);
        }
      }
    });
  }

  Future<int> downloadAndMerge({
    required Iterable<BookmarkSnapshot> local,
    required Future<void> Function(String mergedJson) apply,
    BookmarkWebDavDownloadInvoker? download,
  }) async {
    return _withSyncLock(() async {
      final config = await _readyConfig();
      final bytes = await (download ?? _defaultDownload)(
        url: config.url,
        username: config.account,
        password: config.password,
        remotePath: remotePath(config),
      );
      final merged = BookmarkService.mergeRemote(
        local,
        BookmarkService.decodeJson(utf8.decode(bytes)),
      );
      await apply(BookmarkService.encodeJson(merged));
      return merged.length;
    });
  }

  Future<T> _withSyncLock<T>(Future<T> Function() action) async {
    final previous = _syncTail;
    final release = Completer<void>();
    _syncTail = release.future;
    await previous;
    try {
      return await action();
    } finally {
      release.complete();
    }
  }

  static Future<WebDavConfig> _readyConfig() async {
    final config = await WebDavPrefs.load();
    if (!config.isReady) throw StateError('请先配置 WebDAV');
    return config;
  }

  static bool _isNotFound(Object error) {
    return error.toString().contains('HTTP 404');
  }

  static bool _isPreconditionFailed(Object error) {
    final message = error.toString();
    return RegExp(r'\b412\b').hasMatch(message) ||
        message.toLowerCase().contains('precondition failed');
  }

  static List<BookmarkSnapshot> _merge(
    Iterable<BookmarkSnapshot> local,
    _RemoteBookmarkSnapshot? remote,
  ) {
    if (remote == null) return local.toList(growable: false);
    return BookmarkService.mergeRemote(local, remote.bookmarks);
  }

  static Future<_RemoteBookmarkSnapshot?> _readRemote({
    required WebDavConfig config,
    required BookmarkWebDavDownloadInvoker download,
    required BookmarkWebDavListInvoker? list,
  }) async {
    var etagKnown = false;
    String? etag;
    if (list != null) {
      try {
        final entries = await list(
          url: config.url,
          username: config.account,
          password: config.password,
          path: config.dir,
        );
        etagKnown = true;
        for (final entry in entries) {
          if (!entry.isDir &&
              (entry.name == 'bookmark.json' ||
                  entry.path.endsWith('/bookmark.json'))) {
            etag = entry.etag;
            break;
          }
        }
      } catch (_) {
        // Keep the legacy download/upload path available when PROPFIND is
        // unsupported or temporarily unavailable.
        etagKnown = false;
      }
    }

    try {
      final bytes = await download(
        url: config.url,
        username: config.account,
        password: config.password,
        remotePath: remotePath(config),
      );
      return _RemoteBookmarkSnapshot(
        BookmarkService.decodeJson(utf8.decode(bytes)),
        etag: etag,
        etagKnown: etagKnown,
        exists: true,
      );
    } catch (error) {
      if (!_isNotFound(error)) rethrow;
      if (!etagKnown) return null;
      return _RemoteBookmarkSnapshot(
        const [],
        etag: etag,
        etagKnown: true,
        exists: false,
      );
    }
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

  Future<void> _defaultUpload({
    required String url,
    required String username,
    required String password,
    required String remotePath,
    required List<int> data,
  }) {
    return _webdav.upload(
      url: url,
      username: username,
      password: password,
      remotePath: remotePath,
      data: data,
    );
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

class _RemoteBookmarkSnapshot {
  const _RemoteBookmarkSnapshot(
    this.bookmarks, {
    required this.etag,
    required this.etagKnown,
    required this.exists,
  });

  final List<BookmarkSnapshot> bookmarks;
  final String? etag;
  final bool etagKnown;
  final bool exists;
}
