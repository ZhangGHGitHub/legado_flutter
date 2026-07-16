import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

/// 二维码编解码 — 对齐 Jingshiro [QRCodeUtils]。
class QrCodeService {
  QrCodeService._();

  /// 将文本编码为 PNG 二维码；内容过长或编码失败返回 `null`。
  static Uint8List? encodeToPngBytes(
    String content, {
    int scale = 8,
    int margin = 2,
  }) {
    if (content.isEmpty) return null;
    try {
      final qr = Encoder.encode(content, ErrorCorrectionLevel.l);
      final matrix = qr.matrix;
      if (matrix == null) return null;

      final size = matrix.width;
      final imgSize = (size + margin * 2) * scale;
      final image = img.Image(width: imgSize, height: imgSize);
      img.fill(image, color: img.ColorRgb8(255, 255, 255));

      for (var y = 0; y < size; y++) {
        for (var x = 0; x < size; x++) {
          if (matrix.get(x, y) == 1) {
            img.fillRect(
              image,
              x1: (x + margin) * scale,
              y1: (y + margin) * scale,
              x2: (x + margin + 1) * scale - 1,
              y2: (y + margin + 1) * scale - 1,
              color: img.ColorRgb8(0, 0, 0),
            );
          }
        }
      }
      return Uint8List.fromList(img.encodePng(image));
    } catch (e, st) {
      debugPrint('QrCodeService.encodeToPngBytes failed: $e\n$st');
      return null;
    }
  }

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
