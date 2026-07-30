import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:legado_flutter/application/platform/clipboard_port.dart';
import 'package:legado_flutter/features/bookshelf/import_bookshelf_dialog.dart';

class _FakeClipboardPort implements ClipboardPort {
  _FakeClipboardPort(this.value);

  final String? value;

  @override
  Future<void> copyText(String text) async {}

  @override
  Future<String?> pasteText() async => value;
}

void main() {
  testWidgets('pastes trimmed text through the clipboard port', (tester) async {
    await tester.pumpWidget(
      Provider<ClipboardPort>.value(
        value: _FakeClipboardPort('  [ {"name":"书名"} ]  '),
        child: const MaterialApp(home: Scaffold(body: ImportBookshelfDialog())),
      ),
    );

    await tester.tap(find.text('粘贴'));
    await tester.pump();

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller!.text, '[ {"name":"书名"} ]');
  });
}
