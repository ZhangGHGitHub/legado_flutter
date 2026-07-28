import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/services/http_tts_cache_service.dart';
import 'package:legado_flutter/services/http_tts_service.dart';
import 'package:legado_flutter/services/tts_service.dart';

class _CountingHttpTtsClient extends HttpTtsClient {
  _CountingHttpTtsClient() : super(dio: Dio());

  int fetchCount = 0;

  @override
  Future<Uint8List> fetchAudio(HttpTtsRequest request) async {
    fetchCount++;
    return Uint8List.fromList([1, 2, 3]);
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
