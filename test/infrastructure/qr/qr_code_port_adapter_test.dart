import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/infrastructure/qr/qr_code_port_adapter.dart';
import 'package:legado_flutter/services/qr_code_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('adapter decodes QR image bytes through the application port', () async {
    const payload = '{"bookSourceName":"adapter-test"}';
    final png = QrCodeService.encodeToPngBytes(payload);
    expect(png, isNotNull);

    final result = await const QrCodePortAdapter().decodeFromImageBytes(png!);

    expect(result, payload);
  });

  test('adapter preserves service failure as a null decode result', () async {
    final result = await const QrCodePortAdapter().decodeFromImageBytes(
      Uint8List.fromList(const [1, 2, 3]),
    );

    expect(result, isNull);
  });
}
