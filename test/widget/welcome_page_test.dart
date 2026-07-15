import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/pages/welcome/welcome_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('WelcomePage shows brand texts from activity_welcome', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: WelcomePage()),
    );
    await tester.pump();

    // ems=1 竖排：字符间以换行拼接（对齐 activity_welcome.xml）
    expect(find.text('阅\n读'), findsOneWidget);
    expect(find.text('享\n受\n美\n好\n时\n光'), findsOneWidget);
    expect(find.text('品读万千故事'), findsOneWidget);
  });

  testWidgets('WelcomePage shows intro, privacy and enter/skip actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: WelcomePage()),
    );
    await tester.pump();

    expect(find.textContaining('书架'), findsWidgets);
    expect(find.textContaining('隐私'), findsWidgets);
    expect(find.text('同意并进入'), findsOneWidget);
    expect(find.text('跳过'), findsOneWidget);
  });

  testWidgets('Agree marks welcome completed in SharedPreferences', (
    WidgetTester tester,
  ) async {
    var finished = false;
    await tester.pumpWidget(
      MaterialApp(
        home: WelcomePage(onFinished: () => finished = true),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('同意并进入'));
    await tester.pumpAndSettle();

    expect(finished, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(WelcomePage.welcomeCompletedKey), isTrue);
    expect(prefs.getBool(WelcomePage.privacyAcceptedKey), isTrue);
  });

  testWidgets('Skip marks welcome completed without blocking return users', (
    WidgetTester tester,
  ) async {
    var finished = false;
    await tester.pumpWidget(
      MaterialApp(
        home: WelcomePage(onFinished: () => finished = true),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('跳过'));
    await tester.pumpAndSettle();

    expect(finished, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(WelcomePage.welcomeCompletedKey), isTrue);
    expect(prefs.getBool(WelcomePage.privacyAcceptedKey), isTrue);
  });
}
