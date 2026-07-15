import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:legado_flutter/services/qr_code_service.dart';
import 'package:zxing2/qrcode.dart';

Uint8List _pngWithQr(String content) {
  final qr = Encoder.encode(content, ErrorCorrectionLevel.h);
  final matrix = qr.matrix!;
  const scale = 4;
  const quiet = 4;
  final size = (matrix.width + quiet * 2) * scale;
  final image = img.Image(width: size, height: size);
  img.fill(image, color: img.ColorRgb8(255, 255, 255));
  for (var y = 0; y < matrix.height; y++) {
    for (var x = 0; x < matrix.width; x++) {
      if (matrix.get(x, y) == 1) {
        img.fillRect(
          image,
          x1: (x + quiet) * scale,
          y1: (y + quiet) * scale,
          x2: (x + quiet + 1) * scale - 1,
          y2: (y + quiet + 1) * scale - 1,
          color: img.ColorRgb8(0, 0, 0),
        );
      }
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  test('QrCodeService decodes URL from PNG QR', () {
    const payload = 'https://example.com/bookSource.json';
    final text = QrCodeService.decodeFromImageBytes(_pngWithQr(payload));
    expect(text, payload);
  });

  test('QrCodeService returns null for blank image', () {
    final blank = img.Image(width: 64, height: 64);
    img.fill(blank, color: img.ColorRgb8(255, 255, 255));
    final text = QrCodeService.decodeFromImageBytes(
      Uint8List.fromList(img.encodePng(blank)),
    );
    expect(text, isNull);
  });
}
