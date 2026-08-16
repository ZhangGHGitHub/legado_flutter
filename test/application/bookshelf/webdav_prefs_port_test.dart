import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/bookshelf/webdav_prefs_port.dart';

void main() {
  test('exposes the WebDAV configuration read contract', () async {
    const config = WebDavConfig(
      url: 'https://example.test/dav',
      account: 'reader',
      password: 'secret',
      dir: '/books',
    );
    final port = _MemoryWebDavPrefsPort(config);

    expect(await port.load(), same(config));
  });
}

final class _MemoryWebDavPrefsPort implements WebDavPrefsPort {
  const _MemoryWebDavPrefsPort(this.config);

  final WebDavConfig config;

  @override
  Future<WebDavConfig> load() async => config;
}
