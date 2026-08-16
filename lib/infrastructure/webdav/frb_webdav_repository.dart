import '../../domain/ports/webdav_repository.dart';
import '../../domain/remote/webdav_entry.dart';
import '../../src/rust/api/webdav.dart' as webdav_api;

/// FRB adapter for WebDAV operations used by remote books.
class FrbWebDavRepository implements WebDavRepository {
  const FrbWebDavRepository();

  @override
  Future<void> check({
    required String url,
    required String username,
    required String password,
    required String path,
  }) {
    return webdav_api.webdavCheck(
      url: url,
      username: username,
      password: password,
      path: path,
    );
  }

  @override
  Future<List<WebDavEntry>> list({
    required String url,
    required String username,
    required String password,
    required String path,
  }) async {
    final entries = await webdav_api.webdavList(
      url: url,
      username: username,
      password: password,
      path: path,
    );
    return entries.map(_fromGenerated).toList(growable: false);
  }

  @override
  Future<void> ensureDir({
    required String url,
    required String username,
    required String password,
    required String path,
  }) {
    return webdav_api.webdavEnsureDir(
      url: url,
      username: username,
      password: password,
      path: path,
    );
  }

  @override
  Future<List<int>> download({
    required String url,
    required String username,
    required String password,
    required String remotePath,
  }) {
    return webdav_api.webdavDownload(
      url: url,
      username: username,
      password: password,
      remotePath: remotePath,
    );
  }

  @override
  Future<void> upload({
    required String url,
    required String username,
    required String password,
    required String remotePath,
    required List<int> data,
  }) {
    return webdav_api.webdavUpload(
      url: url,
      username: username,
      password: password,
      remotePath: remotePath,
      data: data,
    );
  }

  @override
  Future<void> uploadIfMatch({
    required String url,
    required String username,
    required String password,
    required String remotePath,
    required List<int> data,
    String? etag,
  }) {
    return webdav_api.webdavUploadIfMatch(
      url: url,
      username: username,
      password: password,
      remotePath: remotePath,
      data: data,
      etag: etag,
    );
  }

  @override
  Future<void> delete({
    required String url,
    required String username,
    required String password,
    required String remotePath,
  }) {
    return webdav_api.webdavDelete(
      url: url,
      username: username,
      password: password,
      remotePath: remotePath,
    );
  }

  @override
  Future<void> move({
    required String url,
    required String username,
    required String password,
    required String remotePath,
    required String destinationPath,
  }) {
    return webdav_api.webdavMove(
      url: url,
      username: username,
      password: password,
      remotePath: remotePath,
      destinationPath: destinationPath,
    );
  }

  static WebDavEntry _fromGenerated(webdav_api.WebDavEntry entry) {
    return WebDavEntry(
      name: entry.name,
      path: entry.path,
      isDir: entry.isDir,
      size: entry.size,
      lastModified: entry.lastModified.toInt(),
      etag: entry.etag,
    );
  }
}
