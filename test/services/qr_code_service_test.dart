import 'package:flutter_test/flutter_test.dart';

import 'package:legado_flutter/services/qr_code_service.dart';

void main() {
  test('encodeToPngBytes produces decodable QR', () {
    const payload = '{"bookSourceName":"test","bookSourceUrl":"https://example.com"}';
    final png = QrCodeService.encodeToPngBytes(payload);
    expect(png, isNotNull);
    expect(png!.length, greaterThan(100));
    final decoded = QrCodeService.decodeFromImageBytes(png);
    expect(decoded, payload);
  });
}
