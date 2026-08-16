import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/app_bootstrap.dart';
import 'package:legado_flutter/services/webdav_prefs.dart';

void main() {
  test('startup WebDAV setup skips incomplete configuration', () async {
    var calls = 0;

    final initialized = await initializeStartupWebDav(
      config: const WebDavConfig(url: 'https://dav.example.com/dav'),
      initialize: () async => calls++,
    );

    expect(initialized, isFalse);
    expect(calls, 0);
  });

  test('startup WebDAV setup runs once for a ready configuration', () async {
    var calls = 0;
    const config = WebDavConfig(
      url: 'https://dav.example.com/dav',
      account: 'account',
      password: 'password',
    );

    final initialized = await initializeStartupWebDav(
      config: config,
      initialize: () async => calls++,
    );

    expect(initialized, isTrue);
    expect(calls, 1);
  });

  test('startup WebDAV setup failure does not block startup', () async {
    const config = WebDavConfig(
      url: 'https://dav.example.com/dav',
      account: 'account',
      password: 'password',
    );

    final initialized = await initializeStartupWebDav(
      config: config,
      initialize: () async => throw StateError('offline'),
    );

    expect(initialized, isFalse);
  });
}
