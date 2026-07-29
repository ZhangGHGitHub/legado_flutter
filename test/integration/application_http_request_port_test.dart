import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/bridge/legado_engine_bridge.dart';
import 'package:legado_flutter/domain/ports/application_http_request_port.dart';
import 'package:legado_flutter/infrastructure/network/frb_application_http_request_port.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('FRB application HTTP port performs a real local roundtrip', () async {
    if (!Platform.isWindows) return;

    await LegadoEngineBridge.tryInit();
    expect(LegadoEngineBridge.isAvailable, isTrue);

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final requestReceived = server.first.then((request) async {
      final body = await utf8.decoder.bind(request).join();
      expect(request.method, 'PUT');
      expect(request.headers.value('x-frb-test'), 'roundtrip');
      expect(body, 'markdown body');
      request.response.statusCode = HttpStatus.conflict;
      request.response.write('conflict body');
      await request.response.close();
    });

    try {
      final response = await const FrbApplicationHttpRequestPort().send(
        url: 'http://127.0.0.1:${server.port}/notes/test.md',
        method: 'PUT',
        headers: const {'X-Frb-Test': 'roundtrip'},
        body: 'markdown body',
        timeoutSeconds: 5,
        policy: ApplicationHttpPolicy.localNetwork,
      );
      expect(response.statusCode, HttpStatus.conflict);
      expect(response.body, 'conflict body');
      await requestReceived;
    } finally {
      await server.close(force: true);
    }
  });
}
