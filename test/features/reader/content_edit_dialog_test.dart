import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/platform/clipboard_port.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/features/reader/content_edit_dialog.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('copies title and content through the clipboard port', (
    tester,
  ) async {
    final clipboard = _FakeClipboard();
    final chapter = Chapter(
      id: 'chapter-1',
      bookId: 'book-1',
      title: '<b>测试章</b>',
      index: 0,
      url: 'https://example.com/chapter-1',
    );

    await tester.pumpWidget(
      Provider<ClipboardPort>.value(
        value: clipboard,
        child: MaterialApp(
          home: ContentEditDialog(
            bookId: chapter.bookId,
            chapter: chapter,
            initialContent: '正文',
            loadRawContent: ({reset = false}) async => '正文',
            onSaved: (_) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('拷贝全部'));
    await tester.pump();

    expect(clipboard.copiedTexts, ['测试章\n正文']);
    expect(find.text('已复制'), findsOneWidget);
  });
}

class _FakeClipboard implements ClipboardPort {
  final copiedTexts = <String>[];

  @override
  Future<void> copyText(String text) async => copiedTexts.add(text);

  @override
  Future<String?> pasteText() async => null;
}
