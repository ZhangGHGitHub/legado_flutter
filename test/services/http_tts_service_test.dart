import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/services/http_tts_service.dart';

void main() {
  test('resolves GET placeholders with encoded speech text', () {
    const config = HttpTtsConfig(
      url: 'https://tts.example/audio?text={{speakText}}&speed={{speed}}',
    );

    final request = config.resolve('你好 世界', 1.25);
    expect(request.method, 'GET');
    expect(
      request.url,
      contains('text=%E4%BD%A0%E5%A5%BD%20%E4%B8%96%E7%95%8C'),
    );
    expect(request.url, endsWith('&speed=1.25'));
  });

  test('resolves AnalyzeUrl style POST body and headers', () {
    const config = HttpTtsConfig(
      url:
          'https://tts.example/audio,{"method":"POST","body":"text={{speakText}}","headers":{"X-Test":"ok"}}',
      contentType: r'audio/(mpeg|wav)',
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    );

    final request = config.resolve('测试', 1.0);
    expect(request.method, 'POST');
    expect(request.body, 'text=测试');
    expect(request.headers['X-Test'], 'ok');
    expect(
      request.headers['Content-Type'],
      'application/x-www-form-urlencoded',
    );
    expect(request.responseContentTypePattern, r'audio/(mpeg|wav)');
  });

  test(
    'rejects a JSON error response instead of passing it to the player',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) {
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"error":"quota"}');
        request.response.close();
      });
      addTearDown(() => server.close(force: true));

      final request = HttpTtsRequest(
        url: 'http://127.0.0.1:${server.port}/tts',
        method: 'GET',
      );
      expect(
        () => HttpTtsClient(dio: Dio()).fetchAudio(request),
        throwsA(isA<StateError>()),
      );
    },
  );

  test('enforces the original response content type pattern', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) {
      request.response.headers.contentType = ContentType('audio', 'wav');
      request.response.add([0, 1, 2]);
      request.response.close();
    });
    addTearDown(() => server.close(force: true));

    final request = HttpTtsRequest(
      url: 'http://127.0.0.1:${server.port}/tts',
      method: 'GET',
      responseContentTypePattern: r'audio/mpeg',
    );
    expect(
      () => HttpTtsClient(dio: Dio()).fetchAudio(request),
      throwsA(isA<StateError>()),
    );
  });
}
