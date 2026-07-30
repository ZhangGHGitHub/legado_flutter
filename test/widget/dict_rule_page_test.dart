import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/platform/clipboard_port.dart';
import 'package:legado_flutter/domain/rules/dict_rule.dart';
import 'package:legado_flutter/features/my/dict_rule_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('copies the selected dictionary rule through ClipboardPort', (
    tester,
  ) async {
    final rule = const DictRule(
      name: '测试规则',
      urlRule: 'https://example.com/{{key}}',
      showRule: 'tag.body',
      enabled: false,
      sortNumber: 7,
    );
    SharedPreferences.setMockInitialValues({
      'dict_rules_v1': jsonEncode([rule.toJson()]),
    });
    final clipboard = _FakeClipboardPort();

    await tester.pumpWidget(
      Provider<ClipboardPort>.value(
        value: clipboard,
        child: const MaterialApp(home: DictRulePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('测试规则'), findsOneWidget);
    expect(find.byType(PopupMenuButton<String>), findsNWidgets(2));
    final ruleMenu = find.descendant(
      of: find.byType(ListView),
      matching: find.byType(PopupMenuButton<String>),
    );
    expect(ruleMenu, findsOneWidget);
    await tester.tap(ruleMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('复制'));
    await tester.pump();

    expect(clipboard.copiedText, jsonEncode(rule.toJson()));
    expect(find.text('已复制规则摘要'), findsOneWidget);
  });
}

class _FakeClipboardPort implements ClipboardPort {
  String? copiedText;

  @override
  Future<void> copyText(String text) async {
    copiedText = text;
  }

  @override
  Future<String?> pasteText() async => null;
}
