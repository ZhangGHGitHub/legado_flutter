import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/application_binary_http_request_port.dart';
import 'package:legado_flutter/domain/ports/application_http_request_port.dart';
import 'package:legado_flutter/infrastructure/reader/read_style_zip_port_adapter.dart';
import 'package:legado_flutter/models/read_style_config.dart';

class _FakeBinaryHttpPort implements ApplicationBinaryHttpRequestPort {
  _FakeBinaryHttpPort(this.response);

  final ApplicationBinaryHttpResponse response;
  String? requestedUrl;

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
    requestedUrl = url;
    return response;
  }
}

Uint8List _configZip() {
  final json = utf8.encode(jsonEncode({'name': 'adapter'}));
  final archive = Archive()
    ..addFile(ArchiveFile('readConfig.json', json.length, json));
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'adapter exposes ZIP import and URL behavior through the port',
    () async {
      final httpPort = _FakeBinaryHttpPort(
        ApplicationBinaryHttpResponse(
          statusCode: 200,
          contentType: 'application/zip',
          body: _configZip(),
        ),
      );
      final port = ReadStyleZipPortAdapter(httpPort);

      final fromBytes = await port.importBytes(_configZip());
      final fromUrl = await port.importFromUrl(
        '  https://example.test/theme.zip ',
      );
      final exported = await port.exportBytes(
        const ReadStyleConfig(name: '导出'),
      );
      final exportedArchive = ZipDecoder().decodeBytes(exported);

      expect(fromBytes.name, 'adapter');
      expect(fromUrl.name, 'adapter');
      expect(httpPort.requestedUrl, 'https://example.test/theme.zip');
      expect(exportedArchive.findFile('readConfig.json'), isNotNull);
    },
  );
}
