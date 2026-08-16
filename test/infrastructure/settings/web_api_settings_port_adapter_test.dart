import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/web_api_status.dart';
import 'package:legado_flutter/infrastructure/settings/web_api_settings_port_adapter.dart';

void main() {
  const status = WebApiStatus(
    running: true,
    port: 9010,
    token: 'token',
    baseUrl: 'http://127.0.0.1:9010',
  );

  test('adapts Web API availability, status, lifecycle and URL', () async {
    final calls = <String>[];
    final adapter = WebApiSettingsPortAdapter(
      isAvailable: () => true,
      currentStatus: () => status,
      setEnabled: (enabled) async {
        calls.add('enabled:$enabled');
        return status;
      },
      start: ({port, token}) async {
        calls.add('start:$port:$token');
        return status;
      },
      apiUrl: (value, path) => '${value.baseUrl}/custom$path',
    );

    expect(adapter.isAvailable, isTrue);
    expect(adapter.currentStatus(), same(status));
    expect(await adapter.setEnabled(false), same(status));
    expect(await adapter.start(port: 9010, token: 'token'), same(status));
    expect(
      adapter.apiUrl(status, '/books'),
      'http://127.0.0.1:9010/custom/books',
    );
    expect(calls, ['enabled:false', 'start:9010:token']);
  });
}
