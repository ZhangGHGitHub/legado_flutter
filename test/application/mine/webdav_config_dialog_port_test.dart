import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/mine/webdav_config_dialog_port.dart';

void main() {
  test(
    'exposes read, save, and connection initialization operations',
    () async {
      const config = WebDavConfig(
        url: 'https://example.test/dav',
        account: 'reader',
        password: 'secret',
      );
      final port = _MemoryWebDavConfigDialogPort(config);

      expect(await port.load(), same(config));
      await port.save(config);
      await port.initialize(config);

      expect(port.saved, same(config));
      expect(port.initialized, same(config));
    },
  );
}

final class _MemoryWebDavConfigDialogPort implements WebDavConfigDialogPort {
  _MemoryWebDavConfigDialogPort(this.config);

  final WebDavConfig config;
  WebDavConfig? saved;
  WebDavConfig? initialized;

  @override
  Future<WebDavConfig> load() async => config;

  @override
  Future<void> save(WebDavConfig config) async {
    saved = config;
  }

  @override
  Future<void> initialize(WebDavConfig config) async {
    initialized = config;
  }
}
