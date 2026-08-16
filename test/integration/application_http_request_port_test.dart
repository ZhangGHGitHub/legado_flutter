import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/bridge/legado_engine_bridge.dart';
import 'package:legado_flutter/domain/ports/application_http_request_port.dart';
import 'package:legado_flutter/infrastructure/network/frb_application_binary_http_request_port.dart';
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

  test('FRB binary HTTP port preserves raw bytes and content type', () async {
    if (!Platform.isWindows) return;

    await LegadoEngineBridge.tryInit();
    expect(LegadoEngineBridge.isAvailable, isTrue);

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final requestReceived = server.first.then((request) async {
      expect(request.method, 'POST');
      expect(
        await request.fold<List<int>>([], (all, chunk) => all..addAll(chunk)),
        [0, 127, 255],
      );
      request.response.statusCode = HttpStatus.partialContent;
      request.response.headers.contentType = ContentType.binary;
      request.response.add([0, 128, 255]);
      await request.response.close();
    });

    try {
      final response = await const FrbApplicationBinaryHttpRequestPort().send(
        url: 'http://127.0.0.1:${server.port}/binary',
        method: 'POST',
        headers: const {'Content-Type': 'application/octet-stream'},
        body: Uint8List.fromList([0, 127, 255]),
        timeoutSeconds: 5,
        maxResponseBytes: 1024,
        policy: ApplicationHttpPolicy.localNetwork,
      );
      expect(response.statusCode, HttpStatus.partialContent);
      expect(response.contentType, startsWith('application/octet-stream'));
      expect(response.body, [0, 128, 255]);
      await requestReceived;
    } finally {
      await server.close(force: true);
    }
  });
}
