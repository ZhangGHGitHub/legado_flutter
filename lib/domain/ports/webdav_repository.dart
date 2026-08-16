import '../remote/webdav_entry.dart';

/// Remote book WebDAV operations needed by the page layer.
abstract interface class WebDavRepository {
  Future<void> check({
    required String url,
    required String username,
    required String password,
    required String path,
  });

  Future<List<WebDavEntry>> list({
    required String url,
    required String username,
    required String password,
    required String path,
  });

  Future<void> ensureDir({
    required String url,
    required String username,
    required String password,
    required String path,
  });

  Future<List<int>> download({
    required String url,
    required String username,
    required String password,
    required String remotePath,
  });

  Future<void> upload({
    required String url,
    required String username,
    required String password,
    required String remotePath,
    required List<int> data,
  });

  Future<void> uploadIfMatch({
    required String url,
    required String username,
    required String password,
    required String remotePath,
    required List<int> data,
    String? etag,
  });

  Future<void> delete({
    required String url,
    required String username,
    required String password,
    required String remotePath,
  });

  Future<void> move({
    required String url,
    required String username,
    required String password,
    required String remotePath,
    required String destinationPath,
  });
}
