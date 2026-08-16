import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/source_rules/check_source_prefs_port.dart';
import 'package:legado_flutter/widgets/check_source_config_dialog.dart';
import 'package:legado_flutter/widgets/check_source_keyword_dialog.dart';

final class _FakeCheckSourcePrefs implements CheckSourcePrefsPort {
  int timeout = 42;
  bool search = false;
  bool discovery = true;
  bool toc = false;
  bool content = true;
  bool debug = false;
  String keyword = '旧关键字';

  @override
  Future<int> timeoutSec() async => timeout;

  @override
  Future<void> setTimeoutSec(int value) async => timeout = value;

  @override
  Future<bool> checkSearch() async => search;

  @override
  Future<void> setCheckSearch(bool value) async => search = value;

  @override
  Future<bool> checkDiscovery() async => discovery;

  @override
  Future<void> setCheckDiscovery(bool value) async => discovery = value;

  @override
  Future<bool> checkToc() async => toc;

  @override
  Future<void> setCheckToc(bool value) async => toc = value;

  @override
  Future<bool> checkContent() async => content;

  @override
  Future<void> setCheckContent(bool value) async => content = value;

  @override
  Future<bool> showDebugMessage() async => debug;

  @override
  Future<void> setShowDebugMessage(bool value) async => debug = value;

  @override
  Future<String> lastKeyword() async => keyword;

  @override
  Future<void> setLastKeyword(String value) async => keyword = value;
}

void main() {
  testWidgets('check config dialog loads and saves through its port', (
    tester,
  ) async {
    final prefs = _FakeCheckSourcePrefs();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  showCheckSourceConfigDialog(context, prefs: prefs),
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    final timeout = tester.widget<TextField>(find.byType(TextField));
    expect(timeout.controller?.text, '42');
    await tester.enterText(find.byType(TextField), '60');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(prefs.timeout, 60);
    expect(prefs.search, isFalse);
    expect(prefs.toc, isFalse);
    expect(prefs.debug, isFalse);
  });

  testWidgets('keyword dialog trims the submitted keyword from its port', (
    tester,
  ) async {
    final prefs = _FakeCheckSourcePrefs();
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showCheckSourceKeywordDialog(
                  context,
                  prefs: prefs,
                );
              },
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    expect(find.text('旧关键字'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '  新关键字  ');
    await tester.tap(find.text('确定校验'));
    await tester.pumpAndSettle();

    expect(result, '新关键字');
  });
}
