import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/platform/clipboard_port.dart';
import 'package:legado_flutter/domain/ports/web_api_port.dart';
import 'package:legado_flutter/domain/web_api_status.dart';
import 'package:legado_flutter/features/settings/web_api_settings_card.dart';
import 'package:legado_flutter/services/web_api_prefs.dart';
import 'package:legado_flutter/services/web_api_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    WebApiService.resetWebApiPort();
    WebApiService.configureWebApiPort(_FakeWebApiPort());
    await WebApiPrefs.save(
      const WebApiConfig(enabled: true, port: 1234, token: 'token'),
    );
  });

  tearDown(WebApiService.resetWebApiPort);

  testWidgets('copies the API URL through the shared clipboard port', (
    tester,
  ) async {
    final clipboard = _FakeClipboard();
    await tester.pumpWidget(
      Provider<ClipboardPort>.value(
        value: clipboard,
        child: const MaterialApp(home: Scaffold(body: WebApiSettingsCard())),
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

class _FakeClipboard implements ClipboardPort {
  final copiedTexts = <String>[];

  @override
  Future<void> copyText(String text) async {
    copiedTexts.add(text);
  }

  @override
  Future<String?> pasteText() async => null;
}

class _FakeWebApiPort implements WebApiPort {
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
  Future<WebApiStatus?> start({
    required int port,
    required String token,
  }) async => currentStatus();

  @override
  Future<void> stop() async {}
}
