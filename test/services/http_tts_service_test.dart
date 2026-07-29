import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/application_binary_http_request_port.dart';
import 'package:legado_flutter/domain/ports/application_http_request_port.dart';
import 'package:legado_flutter/services/http_tts_cache_service.dart';
import 'package:legado_flutter/services/http_tts_service.dart';
import 'package:legado_flutter/services/tts_service.dart';

class _CountingHttpTtsClient extends HttpTtsClient {
  _CountingHttpTtsClient() : super(_FakeBinaryHttpPort());

  int fetchCount = 0;

  @override
  Future<Uint8List> fetchAudio(HttpTtsRequest request) async {
    fetchCount++;
    return Uint8List.fromList([1, 2, 3]);
  }
}

class _BinaryCall {
  const _BinaryCall({
    required this.url,
    required this.method,
    required this.headers,
    required this.body,
    required this.timeoutSeconds,
    required this.maxResponseBytes,
    required this.policy,
  });

  final String url;
  final String method;
  final Map<String, String> headers;
  final Uint8List? body;
  final int timeoutSeconds;
  final int maxResponseBytes;
  final ApplicationHttpPolicy policy;
}

class _FakeBinaryHttpPort implements ApplicationBinaryHttpRequestPort {
  ApplicationBinaryHttpResponse response = ApplicationBinaryHttpResponse(
    statusCode: 200,
    contentType: 'audio/mpeg',
    body: Uint8List.fromList([1, 2, 3]),
  );
  final calls = <_BinaryCall>[];

  @override
  Future<ApplicationBinaryHttpResponse> send({
    required String url,
    required String method,
    Map<String, String> headers = const {},
    Uint8List? body,
    int timeoutSeconds = 30,
    int maxResponseBytes = 0,
    required ApplicationHttpPolicy policy,
  }) async {
    calls.add(
      _BinaryCall(
        url: url,
        method: method,
        headers: Map.of(headers),
        body: body,
        timeoutSeconds: timeoutSeconds,
        maxResponseBytes: maxResponseBytes,
        policy: policy,
      ),
    );
    return response;
  }
}

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
      final port = _FakeBinaryHttpPort()
        ..response = ApplicationBinaryHttpResponse(
          statusCode: 200,
          contentType: 'application/json; charset=utf-8',
          body: Uint8List.fromList(utf8.encode('{"error":"quota"}')),
        );
      const request = HttpTtsRequest(
        url: 'http://127.0.0.1:8080/tts',
        method: 'GET',
      );
      expect(
        () => HttpTtsClient(port).fetchAudio(request),
        throwsA(isA<StateError>()),
      );
    },
  );

  test('enforces the original response content type pattern', () async {
    final port = _FakeBinaryHttpPort()
      ..response = ApplicationBinaryHttpResponse(
        statusCode: 200,
        contentType: 'audio/wav',
        body: Uint8List.fromList([0, 1, 2]),
      );
    const request = HttpTtsRequest(
      url: 'http://127.0.0.1:8080/tts',
      method: 'GET',
      responseContentTypePattern: r'audio/mpeg',
    );
    expect(
      () => HttpTtsClient(port).fetchAudio(request),
      throwsA(isA<StateError>()),
    );
  });

  test('fetchAudio forwards request semantics and the 16 MiB limit', () async {
    final port = _FakeBinaryHttpPort();
    const request = HttpTtsRequest(
      url: 'http://127.0.0.1:8080/tts',
      method: 'POST',
      body: 'text=测试',
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    );

    expect(await HttpTtsClient(port).fetchAudio(request), [1, 2, 3]);
    final call = port.calls.single;
    expect(call.url, request.url);
    expect(call.method, 'POST');
    expect(call.headers, request.headers);
    expect(utf8.decode(call.body!), request.body);
    expect(call.timeoutSeconds, 30);
    expect(call.maxResponseBytes, HttpTtsClient.maxAudioBytes);
    expect(call.policy, ApplicationHttpPolicy.localNetwork);
  });

  test('fetchAudio rejects non-success status', () async {
    final port = _FakeBinaryHttpPort()
      ..response = ApplicationBinaryHttpResponse(
        statusCode: 429,
        contentType: 'audio/mpeg',
        body: Uint8List.fromList([1]),
      );
    expect(
      () => HttpTtsClient(port).fetchAudio(
        const HttpTtsRequest(url: 'http://localhost/tts', method: 'GET'),
      ),
      throwsA(isA<StateError>()),
    );
  });

  group('HttpTtsCacheService', () {
    late Directory directory;
    late HttpTtsCacheService cache;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('legado-http-tts-');
      cache = HttpTtsCacheService(directory: directory);
    });

    tearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });

    test(
      'distinguishes configuration, text, and speed and reuses hits',
      () async {
        const firstConfig = HttpTtsConfig(
          name: 'first',
          url: 'https://tts.example/audio?text={{speakText}}',
        );
        const secondConfig = HttpTtsConfig(
          name: 'second',
          url: 'https://tts.example/audio?text={{speakText}}',
        );
        var fetchCount = 0;
        Future<Uint8List> fetch() async {
          fetchCount++;
          return Uint8List.fromList([fetchCount]);
        }

        final first = await cache.getOrFetch(
          configurationKey: firstConfig.cacheIdentity,
          text: '你好',
          speed: 1,
          fetch: fetch,
        );
        final hit = await cache.getOrFetch(
          configurationKey: firstConfig.cacheIdentity,
          text: '你好',
          speed: 1,
          fetch: fetch,
        );
        await cache.getOrFetch(
          configurationKey: secondConfig.cacheIdentity,
          text: '你好',
          speed: 1,
          fetch: fetch,
        );
        await cache.getOrFetch(
          configurationKey: firstConfig.cacheIdentity,
          text: '再见',
          speed: 1,
          fetch: fetch,
        );
        await cache.getOrFetch(
          configurationKey: firstConfig.cacheIdentity,
          text: '你好',
          speed: 1.1,
          fetch: fetch,
        );

        expect(first, [1]);
        expect(hit, [1]);
        expect(fetchCount, 4);
        expect(
          cache.cacheKey(
            configurationKey: firstConfig.cacheIdentity,
            text: '你好',
            speed: 1,
          ),
          isNot(
            cache.cacheKey(
              configurationKey: firstConfig.cacheIdentity,
              text: '你好',
              speed: 1.1,
            ),
          ),
        );
      },
    );

    test('clear removes audio and the next request fetches again', () async {
      var fetchCount = 0;
      Future<Uint8List> fetch() async {
        fetchCount++;
        return Uint8List.fromList([7]);
      }

      await cache.getOrFetch(
        configurationKey: 'config',
        text: '缓存',
        speed: 1.0,
        fetch: fetch,
      );
      await cache.clear();
      expect(await directory.list().isEmpty, isTrue);
      await cache.getOrFetch(
        configurationKey: 'config',
        text: '缓存',
        speed: 1.0,
        fetch: fetch,
      );

      expect(fetchCount, 2);
    });

    test('failed fetch does not create a reusable cache entry', () async {
      var fetchCount = 0;
      Future<Uint8List> fetch() async {
        fetchCount++;
        if (fetchCount == 1) throw StateError('network failed');
        return Uint8List.fromList([9]);
      }

      Future<Uint8List> request() => cache.getOrFetch(
        configurationKey: 'config',
        text: '失败后重试',
        speed: 1,
        fetch: fetch,
      );

      await expectLater(request(), throwsA(isA<StateError>()));
      expect(await directory.list().isEmpty, isTrue);
      expect(await request(), [9]);
      expect(fetchCount, 2);
    });

    test('coalesces concurrent requests for the same audio', () async {
      var fetchCount = 0;
      final gate = Completer<void>();
      Future<Uint8List> fetch() async {
        fetchCount++;
        await gate.future;
        return Uint8List.fromList([3]);
      }

      final first = cache.getOrFetch(
        configurationKey: 'config',
        text: '并发',
        speed: 1,
        fetch: fetch,
      );
      final second = cache.getOrFetch(
        configurationKey: 'config',
        text: '并发',
        speed: 1,
        fetch: fetch,
      );
      gate.complete();

      expect(await Future.wait([first, second]), [
        [3],
        [3],
      ]);
      expect(fetchCount, 1);
    });
  });

  test('TtsService HTTP path reuses the injected audio cache', () async {
    final directory = await Directory.systemTemp.createTemp('legado-http-tts-');
    final client = _CountingHttpTtsClient();
    final played = <Uint8List>[];
    final tts = TtsService(
      httpClient: client,
      httpCache: HttpTtsCacheService(directory: directory),
      httpAudioSink: (audio) async => played.add(audio),
    )..setEngineId('http');
    tts.configureHttpTts(
      const HttpTtsConfig(url: 'https://tts.example/audio?text={{speakText}}'),
    );

    try {
      await tts.speak('缓存复用。');
      await tts.speak('缓存复用。');
      expect(client.fetchCount, 1);
      expect(played, hasLength(2));
    } finally {
      await tts.stop();
      if (await directory.exists()) await directory.delete(recursive: true);
    }
  });
}
