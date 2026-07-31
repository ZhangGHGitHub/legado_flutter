import 'package:flutter/foundation.dart';

import '../../application/qr/qr_code_port.dart';
import '../../services/qr_code_service.dart';

/// 将现有二维码服务适配到应用端口。
final class QrCodePortAdapter implements QrCodePort {
  const QrCodePortAdapter();

  @override
  Future<String?> decodeFromImageBytes(Uint8List bytes) {
    return compute(QrCodeService.decodeFromImageBytes, bytes);
  }
}
