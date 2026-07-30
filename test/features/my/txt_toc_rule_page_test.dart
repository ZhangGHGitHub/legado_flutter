import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/platform/clipboard_port.dart';
import 'package:legado_flutter/domain/rules/txt_toc_rule.dart';
import 'package:legado_flutter/features/my/txt_toc_rule_page.dart';
import 'package:legado_flutter/services/txt_toc_rule_prefs.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeClipboard implements ClipboardPort {
  final copiedTexts = <String>[];

  @override
  Future<void> copyText(String text) async {
    copiedTexts.add(text);
  }

  @override
  Future<String?> pasteText() async => null;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('copies a TXT toc rule through the shared clipboard port', (
    tester,
  ) async {
    const rule = TxtTocRule(id: 1, name: '测试规则', rule: r'^第\d+章');
    await TxtTocRulePrefs.save([rule]);
    final clipboard = _FakeClipboard();

    await tester.pumpWidget(
      Provider<ClipboardPort>.value(
        value: clipboard,
        child: const MaterialApp(home: TxtTocRulePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('复制正则'));
    await tester.pumpAndSettle();

    expect(clipboard.copiedTexts, [rule.rule]);
    expect(find.text('已复制正则'), findsOneWidget);
  });
}
