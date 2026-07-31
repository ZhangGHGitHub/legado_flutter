import 'dart:typed_data';

/// 二维码图片解码能力。
///
/// 相机实时识别由页面使用的扫描插件负责；本端口只隔离图库图片解码。
abstract interface class QrCodePort {
  Uint8List? encodeToPngBytes(String text);

  Future<String?> decodeFromImageBytes(Uint8List bytes);
}
