import 'dart:convert';

import '../src/rust/api.dart' as rust_api;
import '../src/rust/api/webdav.dart' as webdav_api;
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

/// WebDAV bookmark.json 同步；合并策略由 BookmarkService 统一定义。
class BookmarkSyncService {
  BookmarkSyncService._();

  static String remotePath(WebDavConfig config) {
    final base = config.dir.endsWith('/') ? config.dir : '${config.dir}/';
    return '${base}bookmark.json'.replaceAll(RegExp(r'/{2,}'), '/');
  }

  static Future<int> uploadMerged({
    required Iterable<rust_api.BookmarkDto> local,
    BookmarkWebDavDownloadInvoker download = webdav_api.webdavDownload,
    BookmarkWebDavUploadInvoker upload = webdav_api.webdavUpload,
  }) async {
    final config = await _readyConfig();
    final localItems = local.toList(growable: false);
    var merged = localItems;
    try {
      final bytes = await download(
        url: config.url,
        username: config.account,
        password: config.password,
        remotePath: remotePath(config),
      );
      merged = BookmarkService.mergeRemote(
        localItems,
        BookmarkService.decodeJson(utf8.decode(bytes)),
      );
    } catch (error) {
      if (!_isNotFound(error)) rethrow;
    }
    final json = BookmarkService.encodeJson(merged);
    await upload(
      url: config.url,
      username: config.account,
      password: config.password,
      remotePath: remotePath(config),
      data: utf8.encode(json),
    );
    return merged.length;
  }

  static Future<int> downloadAndMerge({
    required Iterable<rust_api.BookmarkDto> local,
    required Future<void> Function(String mergedJson) apply,
    BookmarkWebDavDownloadInvoker download = webdav_api.webdavDownload,
  }) async {
    final config = await _readyConfig();
    final bytes = await download(
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
  }

  static Future<WebDavConfig> _readyConfig() async {
    final config = await WebDavPrefs.load();
    if (!config.isReady) throw StateError('请先配置 WebDAV');
    return config;
  }

  static bool _isNotFound(Object error) {
    return error.toString().contains('HTTP 404');
  }
}
