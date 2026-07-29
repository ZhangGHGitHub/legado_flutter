import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/application_binary_http_request_port.dart';
import 'package:legado_flutter/domain/ports/application_http_request_port.dart';
import 'package:legado_flutter/models/read_style_config.dart';
import 'package:legado_flutter/services/read_style_zip_service.dart';

class _RequestCall {
  const _RequestCall({
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

class _FakeBinaryHttpRequestPort implements ApplicationBinaryHttpRequestPort {
  _FakeBinaryHttpRequestPort(this.response);

  ApplicationBinaryHttpResponse response;
  final calls = <_RequestCall>[];

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
      _RequestCall(
        url: url,
        method: method,
        headers: headers,
        body: body,
        timeoutSeconds: timeoutSeconds,
        maxResponseBytes: maxResponseBytes,
        policy: policy,
      ),
    );
    return response;
  }
}

ApplicationBinaryHttpResponse _response({
  int statusCode = 200,
  Uint8List? body,
}) {
  return ApplicationBinaryHttpResponse(
    statusCode: statusCode,
    contentType: 'application/zip',
    body: body ?? Uint8List(0),
  );
}

Uint8List _zipBytes(List<ArchiveFile> files) {
  final archive = Archive();
  for (final file in files) {
    archive.addFile(file);
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

Uint8List _validConfigZip() {
  final configBytes = utf8.encode(
    jsonEncode({
      'name': '远程主题',
      'bgStr': '#FFFFFF',
      'bgType': 0,
      'textColor': '#222222',
    }),
  );
  return _zipBytes([
    ArchiveFile('readConfig.json', configBytes.length, configBytes),
  ]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReadStyleConfig', () {
    test('hex roundtrip', () {
      const c = Color(0xFF3E3D3B);
      expect(ReadStyleColorMapper.parse(ReadStyleColorMapper.toHex(c)), c);
    });

    test('fromJson / toJson preserves colors', () {
      final cfg = ReadStyleConfig.fromJson({
        'name': '舒适',
        'bgStr': '#F5F0E8',
        'bgType': 0,
        'textColor': '#3C3C3C',
        'textSize': 22,
        'letterSpacing': 0.05,
      });
      expect(cfg.name, '舒适');
      expect(cfg.dayBgColor, const Color(0xFFF5F0E8));
      expect(cfg.dayTextColor, const Color(0xFF3C3C3C));
      expect(cfg.textSize, 22);
      final round = ReadStyleConfig.fromJson(cfg.toJson());
      expect(round.name, cfg.name);
      expect(round.bgStr, cfg.bgStr);
    });
  });

  group('ReadStyleZipService', () {
    test('importBytes reads readConfig.json from zip', () async {
      final configJson = jsonEncode({
        'name': '导入主题',
        'bgStr': '#FFFFFF',
        'bgType': 0,
        'textColor': '#222222',
        'textAccentColor': '#FF5722',
        'textSize': 18,
        'lineSpacingExtra': 10,
        'paragraphSpacing': 2,
        'paddingLeft': 20,
        'paddingRight': 20,
      });
      final archive = Archive()
        ..addFile(
          ArchiveFile(
            'readConfig.json',
            utf8.encode(configJson).length,
            utf8.encode(configJson),
          ),
        );
      final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
      final service = ReadStyleZipService(
        _FakeBinaryHttpRequestPort(_response()),
      );
      final cfg = await service.importBytes(bytes);
      expect(cfg.name, '导入主题');
      expect(cfg.dayBgColor, const Color(0xFFFFFFFF));
      expect(cfg.dayTextColor, const Color(0xFF222222));
      expect(cfg.textSize, 18);
    });

    test('exportBytes then importBytes roundtrip', () async {
      const original = ReadStyleConfig(
        name: '圆程',
        bgStr: '#C7EDCC',
        textColor: '#2C4C3B',
        textAccentColor: '#4CAF50',
        textSize: 19,
        letterSpacing: 0.02,
      );
      final service = ReadStyleZipService(
        _FakeBinaryHttpRequestPort(_response()),
      );
      final zip = await service.exportBytes(original);
      final back = await service.importBytes(zip);
      expect(back.name, original.name);
      expect(back.bgStr.toUpperCase(), original.bgStr.toUpperCase());
      expect(back.textColor.toUpperCase(), original.textColor.toUpperCase());
      expect(back.textSize, original.textSize);
    });

    test('importBytes fails without readConfig.json', () async {
      final archive = Archive()
        ..addFile(ArchiveFile('readme.txt', 4, utf8.encode('hi')));
      final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
      final service = ReadStyleZipService(
        _FakeBinaryHttpRequestPort(_response()),
      );
      expect(() => service.importBytes(bytes), throwsA(isA<FormatException>()));
    });

    test('importFromUrl uses the binary port contract', () async {
      final port = _FakeBinaryHttpRequestPort(
        _response(body: _validConfigZip()),
      );
      final service = ReadStyleZipService(port);

      final config = await service.importFromUrl(
        '  http://127.0.0.1/theme.zip  ',
      );

      expect(config.name, '远程主题');
      expect(port.calls, hasLength(1));
      final call = port.calls.single;
      expect(call.url, 'http://127.0.0.1/theme.zip');
      expect(call.method, 'GET');
      expect(call.headers, isEmpty);
      expect(call.body, isNull);
      expect(call.timeoutSeconds, 30);
      expect(call.maxResponseBytes, ReadStyleZipService.maxDownloadBytes);
      expect(call.maxResponseBytes, 64 * 1024 * 1024);
      expect(call.policy, ApplicationHttpPolicy.localNetwork);
    });

    test('importFromUrl rejects non-2xx responses', () async {
      final service = ReadStyleZipService(
        _FakeBinaryHttpRequestPort(_response(statusCode: 404)),
      );

      expect(
        () => service.importFromUrl('https://example.com/missing.zip'),
        throwsA(isA<HttpException>()),
      );
    });

    test('importFromUrl rejects an empty response', () async {
      final service = ReadStyleZipService(
        _FakeBinaryHttpRequestPort(_response()),
      );

      expect(
        () => service.importFromUrl('https://example.com/empty.zip'),
        throwsA(isA<FormatException>()),
      );
    });

    test('importBytes rejects parent traversal and absolute paths', () async {
      final service = ReadStyleZipService(
        _FakeBinaryHttpRequestPort(_response()),
      );
      final configBytes = utf8.encode('{}');

      for (final unsafeName in [
        '../readConfig.json',
        r'folder\..\readConfig.json',
        '/readConfig.json',
        r'C:\readConfig.json',
      ]) {
        final bytes = _zipBytes([
          ArchiveFile(unsafeName, configBytes.length, configBytes),
        ]);
        await expectLater(
          service.importBytes(bytes),
          throwsA(isA<FormatException>()),
          reason: unsafeName,
        );
      }
    });

    test(
      'importBytes rejects a file over the decompressed size limit',
      () async {
        final service = ReadStyleZipService(
          _FakeBinaryHttpRequestPort(_response()),
        );
        final bytes = _zipBytes([
          ArchiveFile(
            'oversized.bin',
            ReadStyleZipService.maxArchiveFileBytes + 1,
            const [0],
          ),
        ]);

        expect(
          () => service.importBytes(bytes),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test('importBytes rejects an excessive total decompressed size', () async {
      final service = ReadStyleZipService(
        _FakeBinaryHttpRequestPort(_response()),
      );
      const entrySize = 30 * 1024 * 1024;
      final bytes = _zipBytes([
        for (var index = 0; index < 5; index++)
          ArchiveFile('file-$index.bin', entrySize, const [0]),
      ]);

      expect(() => service.importBytes(bytes), throwsA(isA<FormatException>()));
    });
  });
}
