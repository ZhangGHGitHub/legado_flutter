import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/pages/code_edit/code_edit_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('CodeEditPage shows Jingshiro chrome titles and toolbar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CodeEditPage(initialText: '{"a":1}'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('编辑代码'), findsOneWidget);
    expect(find.byTooltip('搜索'), findsOneWidget);
    expect(find.byTooltip('保存'), findsOneWidget);
    expect(find.text('{"a":1}'), findsOneWidget);
    // KeyboardToolPop 默认片段
    expect(find.text('<js>'), findsOneWidget);
    expect(find.text('@css:'), findsOneWidget);
  });

  testWidgets('CodeEditPage search group matches activity_code_edit', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CodeEditPage(initialText: 'hello world hello'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('搜索'));
    await tester.pumpAndSettle();

    expect(find.text('搜索结果:'), findsOneWidget);
    expect(find.text('正则'), findsOneWidget);
    expect(find.text('查找'), findsOneWidget);
    expect(find.text('上个'), findsOneWidget);
    expect(find.text('下个'), findsOneWidget);
    expect(find.text('替换'), findsOneWidget);
    expect(find.text('全部'), findsOneWidget);
  });

  testWidgets('CodeEditPage save returns text via CodeEditResult', (
    WidgetTester tester,
  ) async {
    CodeEditResult? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await CodeEditPage.open(
                  context,
                  text: 'abc',
                  title: '规则',
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('规则'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'abcd');
    await tester.tap(find.byTooltip('保存'));
    await tester.pumpAndSettle();

    expect(result?.text, 'abcd');
  });
}
