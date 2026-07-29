import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/web_api_port.dart';
import 'package:legado_flutter/domain/web_api_status.dart';
import 'package:legado_flutter/services/web_api_prefs.dart';
import 'package:legado_flutter/services/web_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeWebApiPort implements WebApiPort {
  _FakeWebApiPort({this.available = true});

  final bool available;
  final calls = <String>[];
  WebApiStatus? status;

  @override
  bool get isAvailable => available;

  @override
  WebApiStatus? currentStatus() => status;

  @override
  Future<WebApiStatus?> start({
    required int port,
    required String token,
  }) async {
    calls.add('start:$port:$token');
    status = WebApiStatus(
      running: true,
      port: port,
      token: token,
      baseUrl: 'http://127.0.0.1:$port',
    );
    return status;
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
    status = null;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    WebApiService.resetWebApiPort();
  });

  tearDown(WebApiService.resetWebApiPort);

  test('reset clears the configured Web API port', () async {
    WebApiService.configureWebApiPort(_FakeWebApiPort());
    WebApiService.resetWebApiPort();

    expect(WebApiService.isAvailable, isFalse);
    expect(WebApiService.currentStatus(), isNull);
    await WebApiService.stop();
  });

  test(
    'service starts through the replaceable port and persists status',
    () async {
      final port = _FakeWebApiPort();
      WebApiService.configureWebApiPort(port);
      await WebApiPrefs.save(
        const WebApiConfig(port: 9010, token: 'configured-token'),
      );

      final status = await WebApiService.setEnabled(true);

      expect(status?.port, 9010);
      expect(status?.token, 'configured-token');
      expect(port.calls, ['start:9010:configured-token']);
      final saved = await WebApiPrefs.load();
      expect(saved.enabled, isTrue);
      expect(saved.port, 9010);
      expect(saved.token, 'configured-token');
    },
  );

  test(
    'disabling the service stops the port and persists disabled state',
    () async {
      final port = _FakeWebApiPort();
      WebApiService.configureWebApiPort(port);
      await WebApiPrefs.save(
        const WebApiConfig(enabled: true, port: 9011, token: 'token'),
      );

      await WebApiService.setEnabled(false);

      expect(port.calls, ['stop']);
      expect((await WebApiPrefs.load()).enabled, isFalse);
      expect(WebApiService.currentStatus(), isNull);
    },
  );

  test(
    'unavailable port reports no status without changing configuration',
    () async {
      final port = _FakeWebApiPort(available: false);
      WebApiService.configureWebApiPort(port);
      await WebApiPrefs.save(const WebApiConfig(port: 9012, token: 'token'));

      final status = await WebApiService.setEnabled(true);

      expect(status, isNull);
      expect(port.calls, isEmpty);
      expect((await WebApiPrefs.load()).enabled, isFalse);
    },
  );
}
