import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/platform/clipboard_port.dart';
import 'package:legado_flutter/application/settings/web_api_settings_port.dart';
import 'package:legado_flutter/application/web_api/web_api_prefs_port.dart';
import 'package:legado_flutter/domain/web_api_status.dart';
import 'package:legado_flutter/features/settings/web_api_settings_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('copies the API URL through the shared clipboard port', (
    tester,
  ) async {
    final clipboard = _FakeClipboard();
    await tester.pumpWidget(
      Provider<ClipboardPort>.value(
        value: clipboard,
        child: Provider<WebApiPrefsPort>.value(
          value: const _FakeWebApiPrefs(),
          child: Provider<WebApiSettingsPort>.value(
            value: _FakeWebApiSettings(),
            child: const MaterialApp(
              home: Scaffold(body: WebApiSettingsCard()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('复制 API 地址'));
    await tester.pump();

    expect(clipboard.copiedTexts, ['http://127.0.0.1:1234/api/books']);
    expect(
      find.text('API 地址已复制，Token 请通过 Authorization 请求头传递'),
      findsOneWidget,
    );
  });
}

class _FakeWebApiPrefs implements WebApiPrefsPort {
  const _FakeWebApiPrefs();

  @override
  Future<WebApiConfig> load() async =>
      const WebApiConfig(enabled: true, port: 1234, token: 'token');

  @override
  Future<void> save(WebApiConfig config) async {}
}

class _FakeClipboard implements ClipboardPort {
  final copiedTexts = <String>[];

  @override
  Future<void> copyText(String text) async {
    copiedTexts.add(text);
  }

  @override
  Future<String?> pasteText() async => null;
}

class _FakeWebApiSettings implements WebApiSettingsPort {
  @override
  bool get isAvailable => true;

  @override
  WebApiStatus? currentStatus() => const WebApiStatus(
    running: true,
    port: 1234,
    token: 'token',
    baseUrl: 'http://127.0.0.1:1234',
  );

  @override
  Future<WebApiStatus?> setEnabled(bool enabled) async => currentStatus();

  @override
  Future<WebApiStatus?> start({int? port, String? token}) async =>
      currentStatus();

  @override
  String apiUrl(WebApiStatus status, String path) {
    final sep = path.startsWith('/') ? '' : '/';
    return '${status.baseUrl}$sep$path';
  }
}
