import 'package:legado_flutter/domain/ports/backup_port.dart';
import 'package:legado_flutter/domain/ports/book_progress_sync_store.dart';
import 'package:legado_flutter/domain/ports/webdav_repository.dart';
import 'package:legado_flutter/domain/remote/webdav_entry.dart';

final class MemoryBookProgressSyncStore implements BookProgressSyncStore {
  final values = <String, int>{};

  @override
  Future<int?> read(String key) async => values[key];

  @override
  Future<void> write(String key, int value) async {
    values[key] = value;
  }
}

final class UnavailableBackupPort implements BackupPort {
  const UnavailableBackupPort();

  @override
  bool get isAvailable => false;

  @override
  String get engineVersion => 'test';

  @override
  String exportBackup() => throw UnsupportedError('backup is not configured');

  @override
  void restoreBackup({required String json, required bool replace}) {
    throw UnsupportedError('backup is not configured');
  }
}

final class UnsupportedWebDavRepository implements WebDavRepository {
  const UnsupportedWebDavRepository();

  Never _unsupported() => throw UnsupportedError('WebDAV is not configured');

  @override
  Future<void> check({
    required String url,
    required String username,
    required String password,
    required String path,
  }) async => _unsupported();

  @override
  Future<void> delete({
    required String url,
    required String username,
    required String password,
    required String remotePath,
  }) async => _unsupported();

  @override
  Future<List<int>> download({
    required String url,
    required String username,
    required String password,
    required String remotePath,
  }) async => _unsupported();

  @override
  Future<void> ensureDir({
    required String url,
    required String username,
    required String password,
    required String path,
  }) async => _unsupported();

  @override
  Future<List<WebDavEntry>> list({
    required String url,
    required String username,
    required String password,
    required String path,
  }) async => _unsupported();

  @override
  Future<void> move({
    required String url,
    required String username,
    required String password,
    required String remotePath,
    required String destinationPath,
  }) async => _unsupported();

  @override
  Future<void> upload({
    required String url,
    required String username,
    required String password,
    required String remotePath,
    required List<int> data,
  }) async => _unsupported();

  @override
  Future<void> uploadIfMatch({
    required String url,
    required String username,
    required String password,
    required String remotePath,
    required List<int> data,
    String? etag,
  }) async => _unsupported();
}
