import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/pages/about/donate_page.dart';

void main() {
  testWidgets('DonatePage shows title, sections and QR entries', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DonatePage()));
    await tester.pump();

    expect(find.text('捐赠'), findsOneWidget);
    expect(find.text('您的支持是我更新的动力'), findsOneWidget);
    expect(find.text('微信'), findsOneWidget);
    expect(find.text('支付宝'), findsOneWidget);
    expect(find.text('QQ'), findsOneWidget);
    expect(find.text('微信赞赏码'), findsOneWidget);
    expect(find.text('支付宝收款二维码'), findsOneWidget);
    expect(find.text('QQ收款二维码'), findsOneWidget);
  });
}
