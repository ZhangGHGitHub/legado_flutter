import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:legado_flutter/application/donate/donate_clipboard_port.dart';
import 'package:legado_flutter/features/my/donate_page.dart';

class _FakeDonateClipboard implements DonateClipboardPort {
  final copiedTexts = <String>[];

  @override
  Future<void> copyText(String text) async {
    copiedTexts.add(text);
  }
}

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
    expect(find.text('QQ 收款二维码'), findsOneWidget);
  });

  testWidgets('copies the WeChat account and keeps the original toast', (
    WidgetTester tester,
  ) async {
    final clipboard = _FakeDonateClipboard();
    await tester.pumpWidget(
      MaterialApp(home: DonatePage(clipboard: clipboard)),
    );
    await tester.pump();

    await tester.tap(find.text('关注公众号'));
    await tester.pumpAndSettle();

    expect(clipboard.copiedTexts, ['开源阅读']);
    expect(find.text('已复制：开源阅读'), findsOneWidget);
  });

  testWidgets(
    'uses the injected clipboard provider when no constructor override exists',
    (WidgetTester tester) async {
      final clipboard = _FakeDonateClipboard();
      await tester.pumpWidget(
        Provider<DonateClipboardPort>.value(
          value: clipboard,
          child: const MaterialApp(home: DonatePage()),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('关注公众号'));
      await tester.pumpAndSettle();

      expect(clipboard.copiedTexts, ['开源阅读']);
    },
  );
}
