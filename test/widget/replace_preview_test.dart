import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:legado_flutter/models/replace_rule.dart';
import 'package:legado_flutter/widgets/replace_preview_panel.dart';

void main() {
  testWidgets('ReplacePreviewPanel shows input and output panes', (
    WidgetTester tester,
  ) async {
    final rules = [
      ReplaceRule(
        id: 'r1',
        name: '去广告',
        pattern: r'笔趣阁.*?更新',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReplacePreviewPanel(
            rules: rules,
            initialSample: '笔趣阁 www.test.com 为你提供最快更新\n正文',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('测试文本'), findsOneWidget);
    expect(find.text('替换结果'), findsOneWidget);
    expect(find.textContaining('已启用 1 / 1'), findsOneWidget);

    final output = tester.widget<SelectableText>(find.byType(SelectableText));
    expect(output.data, contains('正文'));
    expect(output.data, isNot(contains('笔趣阁')));
  });

  testWidgets('ReplacePreviewPanel updates when rules change', (
    WidgetTester tester,
  ) async {
    var rules = <ReplaceRule>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Column(
              children: [
                TextButton(
                  onPressed: () => setState(() {
                    rules = [
                      ReplaceRule(
                        id: 'r1',
                        name: '去提示',
                        pattern: '本章未完',
                      ),
                    ];
                  }),
                  child: const Text('启用规则'),
                ),
                Expanded(
                  child: ReplacePreviewPanel(
                    rules: rules,
                    initialSample: '本章未完，请点击下一页\n正文',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    var output = tester.widget<SelectableText>(find.byType(SelectableText));
    expect(output.data, contains('本章未完'));

    await tester.tap(find.text('启用规则'));
    await tester.pump();

    output = tester.widget<SelectableText>(find.byType(SelectableText));
    expect(output.data, isNot(contains('本章未完')));
    expect(output.data, contains('正文'));
  });
}
