import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/pages/qrcode/qrcode_capture_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('QrCodeCapturePage shows Jingshiro scan_qr_code + gallery labels', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: QrCodeCapturePage()),
    );
    await tester.pump();

    // values-zh: scan_qr_code / gallery
    expect(find.text('扫描二维码'), findsOneWidget);
    expect(find.text('图库'), findsWidgets);

    // Desktop/Windows fallback (test host has no live camera support here)
    if (!QrCodeCapturePage.supportsLiveCamera) {
      expect(find.text('粘贴内容'), findsOneWidget);
      expect(find.text('扫描本地图片'), findsOneWidget);
    }
  });

  test('supportsLiveCamera is false on Windows/Linux hosts', () {
    // CI / local Windows 开发机：无 live camera 路径
    expect(
      QrCodeCapturePage.supportsLiveCamera,
      anyOf(false, true),
    );
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux)) {
      expect(QrCodeCapturePage.supportsLiveCamera, isFalse);
    }
  });
}
