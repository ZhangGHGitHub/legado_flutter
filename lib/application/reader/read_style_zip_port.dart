import 'dart:typed_data';

import '../../models/read_style_config.dart';

/// 阅读样式 ZIP 的导入与导出能力。
abstract interface class ReadStyleZipPort {
  Future<ReadStyleConfig> importBytes(Uint8List bytes);

  Future<ReadStyleConfig> importFromUrl(String url);

  Future<Uint8List> exportBytes(ReadStyleConfig config);
}
