import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/platform/clipboard_port.dart';
import 'package:legado_flutter/application/preferences/code_edit_prefs_port.dart';
import 'package:legado_flutter/application/qr/qr_code_port.dart';
import 'package:legado_flutter/domain/ports/code_edit_prefs_store.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/features/sources/source_editor_page.dart';
import 'package:legado_flutter/services/code_edit_prefs.dart';
import 'package:legado_flutter/infrastructure/qr/qr_code_port_adapter.dart';
import 'package:legado_flutter/infrastructure/preferences/shared_preferences_code_edit_prefs.dart';
import 'package:provider/provider.dart';

void main() {
  setUp(() => CodeEditPrefs.configureStore(_FakeCodeEditPrefsStore()));
  tearDown(CodeEditPrefs.resetStore);

  final source = BookSource(
    bookSourceUrl: 'https://source.example',
    bookSourceName: '测试书源',
  );

  Future<void> pumpEditor(WidgetTester tester, _FakeClipboard clipboard) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Provider<ClipboardPort>.value(
          value: clipboard,
          child: Provider<QrCodePort>.value(
            value: const QrCodePortAdapter(),
            child: Provider<CodeEditPrefsPort>.value(
              value: SharedPreferencesCodeEditPrefs(_FakeCodeEditPrefsStore()),
              child: SourceEditorPage(source: source),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> selectMenuItem(WidgetTester tester, String label) async {
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('copies source JSON through the shared clipboard port', (
    tester,
  ) async {
    final clipboard = _FakeClipboard();
    await pumpEditor(tester, clipboard);

    await selectMenuItem(tester, '拷贝源');

    expect(clipboard.copiedTexts, hasLength(1));
    final copied =
        jsonDecode(clipboard.copiedTexts.single) as Map<String, dynamic>;
    expect(copied['bookSourceUrl'], source.bookSourceUrl);
    expect(copied['bookSourceName'], source.bookSourceName);
    expect(find.text('已拷贝源'), findsOneWidget);
  });

  testWidgets('pastes source JSON through the shared clipboard port', (
    tester,
  ) async {
    final clipboard = _FakeClipboard()
      ..pastedText = jsonEncode({
        'bookSourceUrl': 'https://pasted.example',
        'bookSourceName': '粘贴书源',
      });
    await pumpEditor(tester, clipboard);

    await selectMenuItem(tester, '粘贴源');

    expect(clipboard.pasteCalls, 1);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.controller?.text == 'https://pasted.example',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is TextField && widget.controller?.text == '粘贴书源',
      ),
      findsOneWidget,
    );
  });
}

class _FakeClipboard implements ClipboardPort {
  final copiedTexts = <String>[];
  String? pastedText;
  var pasteCalls = 0;

  @override
  Future<void> copyText(String text) async {
    copiedTexts.add(text);
  }

  @override
  Future<String?> pasteText() async {
    pasteCalls++;
    return pastedText;
  }
}

class _FakeCodeEditPrefsStore implements CodeEditPrefsStore {
  @override
  int? getInt(String key) => null;

  @override
  bool? getBool(String key) => null;

  @override
  List<String>? getStringList(String key) => null;

  @override
  Future<bool> setInt(String key, int value) async => true;

  @override
  Future<bool> setBool(String key, bool value) async => true;

  @override
  Future<bool> setStringList(String key, List<String> value) async => true;

  @override
  Future<bool> remove(String key) async => true;
}
