import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/pages/welcome/welcome_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('WelcomePage shows brand texts from activity_welcome', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WelcomePage(showDuration: Duration(days: 1)),
      ),
    );
    await tester.pump();

    // ems=1 竖排：字符间以换行拼接（对齐 activity_welcome.xml）
    expect(find.text('阅\n读'), findsOneWidget);
    expect(find.text('享\n受\n美\n好\n时\n光'), findsOneWidget);
    expect(find.text('品读万千故事'), findsOneWidget);
  });

  testWidgets('WelcomePage has no onboarding/privacy Material chrome', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WelcomePage(showDuration: Duration(days: 1)),
      ),
    );
    await tester.pump();

    expect(find.text('功能简介'), findsNothing);
    expect(find.text('同意并进入'), findsNothing);
    expect(find.text('跳过'), findsNothing);
    expect(find.text('拒绝并退出'), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('WelcomePage shows Jingshiro icon_read_book asset', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WelcomePage(showDuration: Duration(days: 1)),
      ),
    );
    await tester.pump();

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<AssetImage>());
    expect(
      (image.image as AssetImage).assetName,
      'assets/welcome/icon_read_book.png',
    );
  });

  testWidgets('WelcomePage auto-finishes after showDuration', (
    WidgetTester tester,
  ) async {
    var finished = false;
    await tester.pumpWidget(
      MaterialApp(
        home: WelcomePage(
          showDuration: const Duration(milliseconds: 100),
          onFinished: () => finished = true,
        ),
      ),
    );
    await tester.pump();
    expect(finished, isFalse);

    await tester.pump(const Duration(milliseconds: 100));
    expect(finished, isTrue);
  });

  testWidgets('WelcomePage finishes immediately when duration is zero', (
    WidgetTester tester,
  ) async {
    var finished = false;
    await tester.pumpWidget(
      MaterialApp(
        home: WelcomePage(
          showDuration: Duration.zero,
          onFinished: () => finished = true,
        ),
      ),
    );
    await tester.pump();
    expect(finished, isTrue);
  });
}
