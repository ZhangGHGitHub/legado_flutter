import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:legado_flutter/domain/ports/application_binary_http_request_port.dart';
import 'package:legado_flutter/domain/ports/application_http_request_port.dart';
import 'package:legado_flutter/services/reader_image_cache.dart';

class _FakeBinaryHttpPort implements ApplicationBinaryHttpRequestPort {
  ApplicationBinaryHttpResponse response = ApplicationBinaryHttpResponse(
    statusCode: 200,
    contentType: 'image/png',
    body: Uint8List(0),
  );
  ({
    String url,
    String method,
    Map<String, String> headers,
    int timeoutSeconds,
    int maxResponseBytes,
    ApplicationHttpPolicy policy,
  })?
  call;

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
    call = (
      url: url,
      method: method,
      headers: Map.of(headers),
      timeoutSeconds: timeoutSeconds,
      maxResponseBytes: maxResponseBytes,
      policy: policy,
    );
    return response;
  }
}

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('legado_reader_image_');
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  test('default cache downloads through the binary Rust port', () async {
    final bytes = Uint8List.fromList(
      img.encodePng(img.Image(width: 3, height: 2)),
    );
    final port = _FakeBinaryHttpPort()
      ..response = ApplicationBinaryHttpResponse(
        statusCode: 200,
        contentType: 'image/png',
        body: bytes,
      );
    final cache = await ReaderImageCache.createDefault(
      port,
      directoryOverride: directory,
    );

    expect(
      await cache.loadBytes(
        'http://127.0.0.1/image.png',
        headers: const {'Cookie': 'reader=1'},
      ),
      bytes,
    );
    expect(port.call?.url, 'http://127.0.0.1/image.png');
    expect(port.call?.method, 'GET');
    expect(port.call?.headers, {'Cookie': 'reader=1'});
    expect(port.call?.timeoutSeconds, 20);
    expect(port.call?.maxResponseBytes, ReaderImageCache.maxImageBytes);
    expect(port.call?.policy, ApplicationHttpPolicy.localNetwork);
  });

  test('decodes raster dimensions and caches by source headers', () async {
    final bytes = Uint8List.fromList(
      img.encodePng(img.Image(width: 7, height: 4)),
    );
    var downloads = 0;
    final cache = ReaderImageCache(
      directory: directory,
      downloader: (uri, headers) async {
        downloads++;
        expect(uri.toString(), 'https://example.com/image.png');
        expect(headers, {'Cookie': 'reader=1'});
        return bytes;
      },
    );

    final first = await cache.getSize(
      'https://example.com/image.png',
      headers: const {'Cookie': 'reader=1'},
    );
    final second = await cache.getSize(
      'https://example.com/image.png',
      headers: const {'Cookie': 'reader=1'},
    );

    expect(first?.width, 7);
    expect(first?.height, 4);
    expect(second?.width, 7);
    expect(downloads, 1);
    expect(directory.listSync(), hasLength(1));
  });

  test(
    'reuses disk cache across service instances and coalesces requests',
    () async {
      final bytes = Uint8List.fromList(
        img.encodePng(img.Image(width: 3, height: 2)),
      );
      var firstDownloads = 0;
      final firstCache = ReaderImageCache(
        directory: directory,
        downloader: (uri, headers) async {
          firstDownloads++;
          await Future<void>.delayed(const Duration(milliseconds: 5));
          return bytes;
        },
      );
      final results = await Future.wait([
        firstCache.getSize('https://example.com/same.png'),
        firstCache.getSize('https://example.com/same.png'),
      ]);
      expect(
        results.every((size) => size?.width == 3 && size?.height == 2),
        isTrue,
      );
      expect(firstDownloads, 1);

      var secondDownloads = 0;
      final secondCache = ReaderImageCache(
        directory: directory,
        downloader: (uri, headers) async {
          secondDownloads++;
          return bytes;
        },
      );
      final size = await secondCache.getSize('https://example.com/same.png');
      expect(size?.width, 3);
      expect(size?.height, 2);
      expect(secondDownloads, 0);
    },
  );

  test('rejects unsupported sources and invalid image bytes', () async {
    var downloads = 0;
    final cache = ReaderImageCache(
      directory: directory,
      downloader: (uri, headers) async {
        downloads++;
        return Uint8List.fromList(const [1, 2, 3]);
      },
    );

    expect(await cache.getSize('file:///book/image.png'), isNull);
    expect(await cache.getSize('https://example.com/broken.png'), isNull);
    expect(downloads, 1);
  });

  test('decodes SVG dimensions from attributes and viewBox', () async {
    final cache = ReaderImageCache(
      directory: directory,
      downloader: (uri, headers) async => Uint8List.fromList(
        utf8.encode(
          '<svg viewBox="0 0 240 120" xmlns="http://www.w3.org/2000/svg"></svg>',
        ),
      ),
    );

    final size = await cache.getSize('https://example.com/vector.svg');

    expect(size, const ReaderImageSize(width: 240, height: 120));
  });

  test('prefers SVG width and height attributes over viewBox', () async {
    final cache = ReaderImageCache(
      directory: directory,
      downloader: (uri, headers) async => Uint8List.fromList(
        utf8.encode(
          '<svg width="2in" height="72pt" viewBox="0 0 10 10" '
          'xmlns="http://www.w3.org/2000/svg"></svg>',
        ),
      ),
    );

    final size = await cache.getSize('https://example.com/explicit.svg');

    expect(size, const ReaderImageSize(width: 192, height: 96));
  });
}
