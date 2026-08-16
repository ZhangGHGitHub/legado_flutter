import 'dart:typed_data';

import '../../application/reader/read_style_zip_port.dart';
import '../../domain/ports/application_binary_http_request_port.dart';
import '../../models/read_style_config.dart';
import '../../services/read_style_zip_service.dart';

/// 将现有阅读样式 ZIP 服务适配到应用端口。
final class ReadStyleZipPortAdapter implements ReadStyleZipPort {
  ReadStyleZipPortAdapter(ApplicationBinaryHttpRequestPort httpPort)
    : _service = ReadStyleZipService(httpPort);

  final ReadStyleZipService _service;

  @override
  Future<ReadStyleConfig> importBytes(Uint8List bytes) {
    return _service.importBytes(bytes);
  }

  @override
  Future<ReadStyleConfig> importFromUrl(String url) {
    return _service.importFromUrl(url);
  }

  @override
  Future<Uint8List> exportBytes(ReadStyleConfig config) {
    return _service.exportBytes(config);
  }
}
