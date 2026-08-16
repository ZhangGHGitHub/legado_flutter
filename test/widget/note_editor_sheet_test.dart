import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/annotation/note_editor_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/widgets/note_editor_sheet.dart';

void main() {
  final book = Book(id: 'book-1', name: '测试书', author: '作者');

  testWidgets('saves trimmed note content through the application port', (
    tester,
  ) async {
    final port = _FakeNoteEditorPort();
    await tester.pumpWidget(_host(book, port));
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '  新想法  ');
    await tester.tap(find.widgetWithText(FilledButton, '保存想法'));
    await tester.pumpAndSettle();

    expect(port.id, isNotEmpty);
    expect(port.bookId, 'book-1');
    expect(port.chapterTitle, '第一章');
    expect(port.selectedText, '选中的正文');
    expect(port.noteContent, '新想法');
    expect(port.position, 3);
    expect(port.chapterPos, 44);
  });
}

Widget _host(Book book, NoteEditorPort port) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => FilledButton(
          onPressed: () {
            showNoteEditorSheet(
              context,
              book: book,
              chapterTitle: '第一章',
              selectedText: '选中的正文',
              position: 3,
              chapterPos: 44,
              port: port,
            );
          },
          child: const Text('打开'),
        ),
      ),
    ),
  );
}

final class _FakeNoteEditorPort implements NoteEditorPort {
  String? id;
  String? bookId;
  String? chapterTitle;
  String? selectedText;
  String? noteContent;
  int? position;
  int? chapterPos;

  @override
  bool get isAvailable => true;

  @override
  void save({
    required String id,
    required String bookId,
    required String chapterTitle,
    required String selectedText,
    required String noteContent,
    required int position,
    required int chapterPos,
  }) {
    this.id = id;
    this.bookId = bookId;
    this.chapterTitle = chapterTitle;
    this.selectedText = selectedText;
    this.noteContent = noteContent;
    this.position = position;
    this.chapterPos = chapterPos;
  }
}
