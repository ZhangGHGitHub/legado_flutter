import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/platform/clipboard_port.dart';
import 'package:legado_flutter/features/bookshelf/add_book_url_dialog.dart';

void main() {
  testWidgets('pastes text through the injected clipboard port', (
    tester,
  ) async {
    final clipboard = _FakeClipboard('https://example.com/book');

    await tester.pumpWidget(
      MaterialApp(home: AddBookUrlDialog(clipboard: clipboard)),
    );

    await tester.tap(find.text('粘贴'));
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(clipboard.pasteCalls, 1);
    expect(field.controller!.text, 'https://example.com/book');
  });
}

class _FakeClipboard implements ClipboardPort {
  _FakeClipboard(this.pastedText);

  final String pastedText;
  var pasteCalls = 0;

  @override
  Future<void> copyText(String text) async {}

  @override
  Future<String?> pasteText() async {
    pasteCalls++;
    return pastedText;
  }
}
