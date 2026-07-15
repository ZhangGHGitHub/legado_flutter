import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

/// 从本地图片字节解析二维码 — 对齐 Jingshiro [QRCodeUtils.parseCodeResult]。
class QrCodeService {
  QrCodeService._();

  /// 返回识别到的文本；失败返回 `null`。
  static String? decodeFromImageBytes(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      // 过大图压缩，对齐 DEFAULT_REQ_WIDTH/HEIGHT（480×640）量级
      img.Image image = decoded;
      const maxW = 960;
      const maxH = 1280;
      if (image.width > maxW || image.height > maxH) {
        image = img.copyResize(
          image,
          width: image.width > image.height ? maxW : null,
          height: image.height >= image.width ? maxH : null,
        );
      }

      final rgba = image.convert(numChannels: 4);
      final pixels = rgba
          .getBytes(order: img.ChannelOrder.rgba)
          .buffer
          .asInt32List();
      final source = RGBLuminanceSource(rgba.width, rgba.height, pixels);

      return _decodeSource(source) ??
          _decodeSource(source.invert()) ??
          (source.isRotateSupported
              ? _decodeSource(source.rotateCounterClockwise())
              : null);
    } catch (e, st) {
      debugPrint('QrCodeService.decodeFromImageBytes failed: $e\n$st');
      return null;
    }
  }

  static String? _decodeSource(LuminanceSource source) {
    final reader = QRCodeReader();
    try {
      try {
        return reader
            .decode(BinaryBitmap(HybridBinarizer(source)))
            .text;
      } catch (_) {
        return reader
            .decode(BinaryBitmap(GlobalHistogramBinarizer(source)))
            .text;
      }
    } catch (_) {
      return null;
    }
  }
}
