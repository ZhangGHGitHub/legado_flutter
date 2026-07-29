import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/web_api_data_port.dart';
import 'package:legado_flutter/infrastructure/web_api/dart_io_web_api_port.dart';

class _FakeWebApiDataPort implements WebApiDataPort {
  bool available = true;
  Object? error;
  final calls = <String>[];
  final addedBooks = <Map<String, dynamic>>[];

  @override
  bool get isAvailable => available;

  @override
  Future<void> addBook(Map<String, dynamic> book) async {
    _throwIfNeeded();
    calls.add('addBook');
    addedBooks.add(book);
  }

  @override
  Future<void> deleteBook(String bookId) async {
    _throwIfNeeded();
    calls.add('deleteBook:$bookId');
  }

  @override
  Future<List<Map<String, dynamic>>> listBooks() async {
    _throwIfNeeded();
    calls.add('listBooks');
    return [
      {'id': 'book-1', 'name': '测试书籍'},
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> listChapters(String bookId) async {
    _throwIfNeeded();
    calls.add('listChapters:$bookId');
    return [
      {'id': 'chapter-1', 'title': '第一章'},
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> listSources() async {
    _throwIfNeeded();
    calls.add('listSources');
    return [
      {'bookSourceUrl': 'https://example.com'},
    ];
  }

  @override
  Future<Map<String, dynamic>> readingStats() async {
    _throwIfNeeded();
    calls.add('readingStats');
    return {'totalChars': 123};
  }

  void _throwIfNeeded() {
    final currentError = error;
    if (currentError != null) throw currentError;
  }
}

typedef _Response = ({
  int statusCode,
  ContentType? contentType,
  String? allow,
  Object? body,
  String rawBody,
});

void main() {
  late _FakeWebApiDataPort dataPort;
  late DartIoWebApiPort port;
  late HttpClient client;

  setUp(() {
    dataPort = _FakeWebApiDataPort();
    port = DartIoWebApiPort(dataPort: dataPort);
    client = HttpClient()..findProxy = (_) => 'DIRECT';
  });

  tearDown(() async {
    await port.stop();
    client.close(force: true);
  });

  test('validates configuration and reports the complete lifecycle', () async {
    expect(
      port.start(port: 0, token: 'token'),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          '端口无效',
        ),
      ),
    );
    expect(
      port.start(port: 65536, token: 'token'),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          '端口无效',
        ),
      ),
    );
    expect(
      port.start(port: await _unusedPort(), token: '   '),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          'Token 不能为空',
        ),
      ),
    );

    final firstPort = await _unusedPort();
    final first = (await port.start(port: firstPort, token: '  secret  '))!;
    expect(first.running, isTrue);
    expect(first.port, firstPort);
    expect(first.token, 'secret');
    expect(first.baseUrl, 'http://127.0.0.1:$firstPort');
    expect(port.currentStatus().baseUrl, first.baseUrl);

    final secondPort = await _unusedPort();
    final second = (await port.start(port: secondPort, token: 'next'))!;
    expect(second.port, secondPort);
    final rebound = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      firstPort,
    );
    await rebound.close(force: true);

    await port.stop();
    expect(port.currentStatus().running, isFalse);
    expect(port.currentStatus().port, 0);
    expect(port.currentStatus().token, isEmpty);
    expect(port.currentStatus().baseUrl, isEmpty);

    dataPort.available = false;
    expect(await port.start(port: await _unusedPort(), token: 'token'), isNull);
  });

  test(
    'health is public and protected routes accept both token forms',
    () async {
      final baseUrl = await _start(port, token: 'secret');

      final health = await _request(client, baseUrl, 'GET', '/api/health');
      expect(health.statusCode, HttpStatus.ok);
      expect(health.contentType?.mimeType, ContentType.json.mimeType);
      expect(health.body, {'status': 'ok', 'version': '0.5.1'});

      final head = await _request(client, baseUrl, 'HEAD', '/api/health');
      expect(head.statusCode, HttpStatus.ok);
      expect(head.rawBody, isEmpty);

      final missing = await _request(client, baseUrl, 'GET', '/api/books');
      expect(missing.statusCode, HttpStatus.unauthorized);
      expect(missing.body, {'error': '无效 Token'});

      final invalid = await _request(
        client,
        baseUrl,
        'GET',
        '/api/books',
        token: 'wrong',
      );
      expect(invalid.statusCode, HttpStatus.unauthorized);
      expect(invalid.body, {'error': '无效 Token'});

      final bearer = await _request(
        client,
        baseUrl,
        'GET',
        '/api/books',
        token: 'Bearer secret',
      );
      final plain = await _request(
        client,
        baseUrl,
        'GET',
        '/api/books',
        token: 'secret',
      );
      expect(bearer.statusCode, HttpStatus.ok);
      expect(plain.statusCode, HttpStatus.ok);
    },
  );

  test('dispatches every data route and preserves status codes', () async {
    final baseUrl = await _start(port, token: 'secret');

    final books = await _request(
      client,
      baseUrl,
      'GET',
      '/api/books',
      token: 'Bearer secret',
    );
    expect(books.body, [
      {'id': 'book-1', 'name': '测试书籍'},
    ]);

    final added = await _request(
      client,
      baseUrl,
      'POST',
      '/api/books',
      token: 'secret',
      body: {'id': 'book-2', 'name': '新增书籍'},
    );
    expect(added.statusCode, HttpStatus.created);
    expect(added.rawBody, isEmpty);

    final deleted = await _request(
      client,
      baseUrl,
      'DELETE',
      '/api/books/book-2',
      token: 'secret',
    );
    expect(deleted.statusCode, HttpStatus.noContent);
    expect(deleted.rawBody, isEmpty);

    final chapters = await _request(
      client,
      baseUrl,
      'GET',
      '/api/books/book-1/chapters',
      token: 'secret',
    );
    expect(chapters.body, [
      {'id': 'chapter-1', 'title': '第一章'},
    ]);

    final sources = await _request(
      client,
      baseUrl,
      'GET',
      '/api/sources',
      token: 'secret',
    );
    expect(sources.body, [
      {'bookSourceUrl': 'https://example.com'},
    ]);

    final records = await _request(
      client,
      baseUrl,
      'GET',
      '/api/records',
      token: 'secret',
    );
    expect(records.body, {'totalChars': 123});
    expect(dataPort.calls, [
      'listBooks',
      'addBook',
      'deleteBook:book-2',
      'listChapters:book-1',
      'listSources',
      'readingStats',
    ]);
    expect(dataPort.addedBooks, [
      {'id': 'book-2', 'name': '新增书籍'},
    ]);
  });

  test('returns the original empty 404 and 405 responses', () async {
    final baseUrl = await _start(port, token: 'secret');

    final notFound = await _request(client, baseUrl, 'GET', '/api/unknown');
    expect(notFound.statusCode, HttpStatus.notFound);
    expect(notFound.contentType, isNull);
    expect(notFound.rawBody, isEmpty);

    final methodNotAllowed = await _request(
      client,
      baseUrl,
      'PUT',
      '/api/books',
      token: 'secret',
    );
    expect(methodNotAllowed.statusCode, HttpStatus.methodNotAllowed);
    expect(methodNotAllowed.contentType, isNull);
    expect(methodNotAllowed.allow, 'GET,HEAD,POST');
    expect(methodNotAllowed.rawBody, isEmpty);
  });

  test('maps unavailable data to 503 and other failures to 500', () async {
    final baseUrl = await _start(port, token: 'secret');

    dataPort.error = const WebApiDataUnavailable('数据库未初始化');
    final unavailable = await _request(
      client,
      baseUrl,
      'GET',
      '/api/books',
      token: 'secret',
    );
    expect(unavailable.statusCode, HttpStatus.serviceUnavailable);
    expect(unavailable.body, {'error': '数据库未初始化'});

    dataPort.error = Exception('读取失败');
    final failed = await _request(
      client,
      baseUrl,
      'GET',
      '/api/books',
      token: 'secret',
    );
    expect(failed.statusCode, HttpStatus.internalServerError);
    expect(failed.body, {'error': '读取失败'});
  });
}

Future<int> _unusedPort() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final port = server.port;
  await server.close(force: true);
  return port;
}

Future<String> _start(DartIoWebApiPort port, {required String token}) async {
  final status = await port.start(port: await _unusedPort(), token: token);
  return status!.baseUrl;
}

Future<_Response> _request(
  HttpClient client,
  String baseUrl,
  String method,
  String path, {
  String? token,
  Object? body,
}) async {
  final request = await client.openUrl(method, Uri.parse('$baseUrl$path'));
  if (token != null) {
    request.headers.set(HttpHeaders.authorizationHeader, token);
  }
  if (body != null) {
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(body));
  }
  final response = await request.close();
  final rawBody = await utf8.decoder.bind(response).join();
  return (
    statusCode: response.statusCode,
    contentType: response.headers.contentType,
    allow: response.headers.value(HttpHeaders.allowHeader),
    body: rawBody.isEmpty ? null : jsonDecode(rawBody),
    rawBody: rawBody,
  );
}
