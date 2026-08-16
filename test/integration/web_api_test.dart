import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/web_api/repository_web_api_data_port.dart';
import 'package:legado_flutter/bridge/legado_db_bridge.dart';
import 'package:legado_flutter/bridge/legado_engine_bridge.dart';
import 'package:legado_flutter/database/dao/book_dao.dart';
import 'package:legado_flutter/database/dao/source_dao.dart';
import 'package:legado_flutter/infrastructure/engine/frb_reading_record_port.dart';
import 'package:legado_flutter/infrastructure/web_api/dart_io_web_api_port.dart';
import 'package:path/path.dart' as p;

void main() {
  group('Web API Dart IO + Rust 数据集成', () {
    late bool rustReady;

    setUpAll(() async {
      await LegadoEngineBridge.tryInit();
      rustReady = LegadoEngineBridge.isAvailable;
      if (rustReady) {
        final tempDir = await Directory.systemTemp.createTemp('legado_webapi_');
        await LegadoDbBridge.init(
          dbPathOverride: p.join(tempDir.path, 'legado.db'),
        );
      }
    });

    test(
      'serves the existing HTTP contract through application ports',
      () async {
        if (!rustReady) return;

        final server = DartIoWebApiPort(
          dataPort: RepositoryWebApiDataPort(
            bookRepository: BookDao(),
            sourceRepository: SourceDao(),
            readingRecordPort: FrbReadingRecordPort(),
            isDatabaseReady: () => LegadoDbBridge.isReady,
          ),
        );
        final port = await _unusedLoopbackPort();
        addTearDown(server.stop);

        final status = await server.start(port: port, token: ' itest ');
        expect(status?.running, isTrue);
        expect(status?.port, port);
        expect(status?.token, 'itest');
        expect(server.currentStatus().running, status?.running);
        expect(server.currentStatus().port, status?.port);
        expect(server.currentStatus().token, status?.token);
        expect(server.currentStatus().baseUrl, status?.baseUrl);

        final health = await _request(port, 'GET', '/api/health');
        expect(health.status, HttpStatus.ok);
        expect(jsonDecode(health.body), {'status': 'ok', 'version': '0.5.1'});

        final unauthorized = await _request(port, 'GET', '/api/books');
        expect(unauthorized.status, HttpStatus.unauthorized);

        final created = await _request(
          port,
          'POST',
          '/api/books',
          token: 'itest',
          body: {'id': 'web-book', 'name': 'Web API 测试书'},
        );
        expect(created.status, HttpStatus.created);

        final books = await _request(
          port,
          'GET',
          '/api/books',
          token: 'Bearer itest',
        );
        expect((jsonDecode(books.body) as List).single['id'], 'web-book');

        final chapters = await _request(
          port,
          'GET',
          '/api/books/web-book/chapters',
          token: 'itest',
        );
        expect(jsonDecode(chapters.body), isEmpty);

        final sources = await _request(
          port,
          'GET',
          '/api/sources',
          token: 'itest',
        );
        expect(jsonDecode(sources.body), isEmpty);

        final records = await _request(
          port,
          'GET',
          '/api/records',
          token: 'itest',
        );
        expect((jsonDecode(records.body) as Map)['totalChars'], 0);

        final deleted = await _request(
          port,
          'DELETE',
          '/api/books/web-book',
          token: 'itest',
        );
        expect(deleted.status, HttpStatus.noContent);

        await server.stop();
        expect(server.currentStatus().running, isFalse);
      },
    );
  });
}

Future<int> _unusedLoopbackPort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

Future<({int status, String body})> _request(
  int port,
  String method,
  String path, {
  String? token,
  Map<String, dynamic>? body,
}) async {
  final client = HttpClient();
  try {
    final request = await client.openUrl(
      method,
      Uri.parse('http://127.0.0.1:$port$path'),
    );
    if (token != null) {
      request.headers.set(HttpHeaders.authorizationHeader, token);
    }
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }
    final response = await request.close();
    return (
      status: response.statusCode,
      body: await utf8.decoder.bind(response).join(),
    );
  } finally {
    client.close(force: true);
  }
}
