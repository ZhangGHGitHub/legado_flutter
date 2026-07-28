import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/models/dict_rule.dart';
import 'package:legado_flutter/widgets/dict_lookup_sheet.dart';

void main() {
  final rules = [
    const DictRule(name: '禁用', enabled: false, sortNumber: 0),
    const DictRule(name: '第二', enabled: true, sortNumber: 2),
    const DictRule(name: '第一', enabled: true, sortNumber: 1),
  ];

  Widget host({required DictRuleQuery query, DictRulesLoader? loadRules}) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 420,
          child: DictLookupSheet(
            word: '测试词',
            loadRules: loadRules ?? (() async => rules),
            queryRule: query,
          ),
        ),
      ),
    );
  }

  testWidgets('loads enabled rules in order and queries the first tab', (
    tester,
  ) async {
    final calls = <String>[];
    await tester.pumpWidget(
      host(
        query: (rule, word) async {
          calls.add(rule.name);
          return '${rule.name}结果:$word';
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('禁用'), findsNothing);
    expect(find.text('第一'), findsOneWidget);
    expect(find.text('第二'), findsOneWidget);
    expect(find.text('第一结果:测试词'), findsOneWidget);
    expect(calls, ['第一']);
  });

  testWidgets('tab switching isolates an older query result', (tester) async {
    final first = Completer<String>();
    final calls = <String>[];
    await tester.pumpWidget(
      host(
        query: (rule, word) {
          calls.add(rule.name);
          if (rule.name == '第一') return first.future;
          return Future.value('第二结果');
        },
      ),
    );
    await tester.pump();
    await tester.tap(find.text('第二'));
    await tester.pumpAndSettle();

    expect(find.text('第二结果'), findsOneWidget);
    expect(calls, ['第一', '第二']);

    first.complete('过期的第一结果');
    await tester.pump();
    expect(find.text('第二结果'), findsOneWidget);
    expect(find.text('过期的第一结果'), findsNothing);
  });

  testWidgets('query failure is shown in the active tab', (tester) async {
    await tester.pumpWidget(
      host(query: (rule, word) async => throw StateError('网络不可用')),
    );
    await tester.pumpAndSettle();

    expect(find.text('查询失败：Bad state: 网络不可用'), findsOneWidget);
  });

  testWidgets('empty selected text does not open a sheet', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDictLookupSheet(context, '  '),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();

    expect(find.text('无法查询空文本'), findsOneWidget);
    expect(find.byType(DictLookupSheet), findsNothing);
  });

  testWidgets('renders HTML result media and invokes dictionary buttons', (
    tester,
  ) async {
    final calls = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DictResultContent(
            rule: rules[1],
            content:
                '<h3>释义</h3><p><strong>重点</strong><br>说明</p>'
                '<img src="https://example.com/word.png">'
                '<button name="播放" data-click="play">按钮</button>',
            onButtonClick: (rule, name, click) async {
              calls.add('$name:$click');
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('释义'), findsOneWidget);
    expect(_findSelectableTextContaining('重点'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    await tester.tap(find.text('按钮'));
    expect(calls, ['播放:play']);
  });

  testWidgets('renders the original md result marker', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DictResultContent(
            rule: rules[1],
            content:
                '<md># 标题\n\n**重点**\n\n![插图](https://example.com/a.png)</md>',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(_findRichTextContaining('标题'), findsOneWidget);
    expect(_findRichTextContaining('重点'), findsOneWidget);
  });
}

Finder _findSelectableTextContaining(String value) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is SelectableText &&
        widget.textSpan?.toPlainText().contains(value) == true,
  );
}

Finder _findRichTextContaining(String value) {
  return find.byWidgetPredicate(
    (widget) => widget is RichText && widget.text.toPlainText().contains(value),
  );
}
