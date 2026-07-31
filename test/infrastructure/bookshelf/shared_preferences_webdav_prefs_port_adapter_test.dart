import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/preferences/shared_preferences_runtime.dart';
import 'package:legado_flutter/infrastructure/bookshelf/shared_preferences_webdav_prefs_port_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('reads existing WebDAV keys and defaults through the adapter', () async {
    SharedPreferences.setMockInitialValues({
      'webdav_url': 'https://example.test/dav',
      'webdav_account': 'reader',
      'webdav_password': 'secret',
      'webdav_dir': '/legado',
      'webdav_device': 'Test device',
    });
    SharedPreferencesRuntime.resetForTest();

    const adapter = SharedPreferencesWebDavPrefsPortAdapter();
    final config = await adapter.load();

    expect(config.url, 'https://example.test/dav');
    expect(config.account, 'reader');
    expect(config.password, 'secret');
    expect(config.booksDir, '/legado/books');
    expect(config.device, 'Test device');
  });
}
