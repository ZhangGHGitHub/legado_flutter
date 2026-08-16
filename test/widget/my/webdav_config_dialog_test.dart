import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/mine/webdav_config_dialog_port.dart';
import 'package:legado_flutter/features/my/webdav_config_dialog.dart';

void main() {
  testWidgets('loads configuration through the injected port', (tester) async {
    const loaded = WebDavConfig(
      url: 'https://example.test/dav',
      account: 'reader',
      password: 'secret',
      dir: '/remote',
      device: 'Test device',
    );
    final port = _FakeWebDavConfigDialogPort(loaded);

    await tester.pumpWidget(MaterialApp(home: WebDavConfigDialog(port: port)));
    await tester.pump();

    expect(_text(tester, 0), loaded.url);
    expect(_text(tester, 1), loaded.account);
    expect(_text(tester, 2), loaded.password);
    expect(_text(tester, 3), loaded.dir);
    expect(_text(tester, 4), loaded.device);
  });

  testWidgets('saves and initializes a ready configuration through the port', (
    tester,
  ) async {
    const initial = WebDavConfig(
      url: 'https://example.test/dav',
      account: 'reader',
      password: 'secret',
    );
    final port = _FakeWebDavConfigDialogPort(initial);

    await tester.pumpWidget(
      MaterialApp(
        home: WebDavConfigDialog(initial: initial, port: port),
      ),
    );
    await tester.tap(find.text('保存'));
    await tester.pump();

    _expectConfig(port.saved, initial);
    _expectConfig(port.initialized, initial);
  });

  testWidgets('saves incomplete configuration without testing the connection', (
    tester,
  ) async {
    const initial = WebDavConfig(url: 'https://example.test/dav');
    final port = _FakeWebDavConfigDialogPort(initial);

    await tester.pumpWidget(
      MaterialApp(
        home: WebDavConfigDialog(initial: initial, port: port),
      ),
    );
    await tester.tap(find.text('保存'));
    await tester.pump();

    _expectConfig(port.saved, initial);
    expect(port.initialized, isNull);
  });
}

String _text(WidgetTester tester, int index) =>
    tester.widget<TextField>(find.byType(TextField).at(index)).controller!.text;

void _expectConfig(WebDavConfig? actual, WebDavConfig expected) {
  expect(actual, isNotNull);
  expect(actual!.url, expected.url);
  expect(actual.account, expected.account);
  expect(actual.password, expected.password);
  expect(actual.dir, expected.dir);
  expect(actual.device, expected.device);
}

final class _FakeWebDavConfigDialogPort implements WebDavConfigDialogPort {
  _FakeWebDavConfigDialogPort(this.loaded);

  final WebDavConfig loaded;
  WebDavConfig? saved;
  WebDavConfig? initialized;

  @override
  Future<WebDavConfig> load() async => loaded;

  @override
  Future<void> save(WebDavConfig config) async {
    saved = config;
  }

  @override
  Future<void> initialize(WebDavConfig config) async {
    initialized = config;
  }
}
