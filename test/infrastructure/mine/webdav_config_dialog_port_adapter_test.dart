import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/bookshelf/webdav_prefs_port.dart';
import 'package:legado_flutter/domain/ports/webdav_repository.dart';
import 'package:legado_flutter/domain/remote/webdav_entry.dart';
import 'package:legado_flutter/infrastructure/mine/webdav_config_dialog_port_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'preserves WebDAV preference keys and delegates setup operations',
    () async {
      SharedPreferences.setMockInitialValues({
        'webdav_url': 'https://example.test/dav',
        'webdav_account': 'reader',
        'webdav_password': 'secret',
        'webdav_dir': '/legado',
        'webdav_device': 'Test device',
      });
      final repository = _RecordingWebDavRepository();
      final adapter = WebDavConfigDialogPortAdapter(repository: repository);

      final loaded = await adapter.load();
      expect(loaded.url, 'https://example.test/dav');
      expect(loaded.account, 'reader');
      expect(loaded.password, 'secret');
      expect(loaded.dir, '/legado');
      expect(loaded.device, 'Test device');

      const saved = WebDavConfig(
        url: 'https://saved.test/dav',
        account: 'saved-user',
        password: 'saved-password',
        dir: '/saved',
        device: 'Saved device',
      );
      await adapter.save(saved);
      final reloaded = await adapter.load();
      expect(reloaded.url, saved.url);
      expect(reloaded.account, saved.account);
      expect(reloaded.password, saved.password);
      expect(reloaded.dir, saved.dir);
      expect(reloaded.device, saved.device);

      await adapter.initialize(saved);
      expect(repository.checkedPath, '/saved');
      expect(repository.ensurePaths, [
        '/saved',
        '/saved/bookProgress',
        '/saved/books',
        '/saved/background',
      ]);
    },
  );
}

final class _RecordingWebDavRepository implements WebDavRepository {
  String? checkedPath;
  final ensurePaths = <String>[];

  @override
  Future<void> check({
    required String url,
    required String username,
    required String password,
    required String path,
  }) async {
    checkedPath = path;
  }

  @override
  Future<void> ensureDir({
    required String url,
    required String username,
    required String password,
    required String path,
  }) async {
    ensurePaths.add(path);
  }

  @override
  Future<List<WebDavEntry>> list({
    required String url,
    required String username,
    required String password,
    required String path,
  }) async => [];

  @override
  Future<List<int>> download({
    required String url,
    required String username,
    required String password,
    required String remotePath,
  }) async => [];

  @override
  Future<void> upload({
    required String url,
    required String username,
    required String password,
    required String remotePath,
    required List<int> data,
  }) async {}

  @override
  Future<void> uploadIfMatch({
    required String url,
    required String username,
    required String password,
    required String remotePath,
    required List<int> data,
    String? etag,
  }) async {}

  @override
  Future<void> delete({
    required String url,
    required String username,
    required String password,
    required String remotePath,
  }) async {}

  @override
  Future<void> move({
    required String url,
    required String username,
    required String password,
    required String remotePath,
    required String destinationPath,
  }) async {}
}
