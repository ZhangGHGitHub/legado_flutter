import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/platform/clipboard_port.dart';
import 'package:legado_flutter/features/bookshelf/app_log_page.dart';
import 'package:legado_flutter/infrastructure/reader/reader_font_port_adapter.dart';
import 'package:legado_flutter/infrastructure/diagnostics/app_log_port_adapter.dart';
import 'package:legado_flutter/services/app_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeClipboard implements ClipboardPort {
  String? pastedText;
  final copiedTexts = <String>[];

  @override
  Future<void> copyText(String text) async {
    copiedTexts.add(text);
  }

  @override
  Future<String?> pasteText() async => pastedText;
}

void main() {
  SharedPreferences.setMockInitialValues({});

  testWidgets('AppLogPage copies the complete log text through its port', (
    tester,
  ) async {
    await AppLog.clear();
    await AppLog.put('first');
    await AppLog.put('second', level: 'W');
    final clipboard = _FakeClipboard();

    await tester.pumpWidget(
      MaterialApp(
        home: AppLogPage(
          clipboard: clipboard,
          log: const AppLogPortAdapter(),
          font: const ReaderFontPortAdapter(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('复制'));
    await tester.pump();

    expect(clipboard.copiedTexts, hasLength(1));
    expect(clipboard.copiedTexts.single, contains('[W] second'));
    expect(clipboard.copiedTexts.single, contains('[I] first'));
    expect(find.text('已复制全部日志'), findsOneWidget);

    await AppLog.clear();
  });
}
