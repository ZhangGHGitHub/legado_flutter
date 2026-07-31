import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:legado_flutter/application/bookshelf/bookshelf_list_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/ports/public_text_fetch_port.dart';
import 'package:legado_flutter/features/bookshelf/import_bookshelf_dialog.dart';

final class _FakeBookshelfListPort implements BookshelfListPort {
  @override
  Future<String?> exportBooks(List<Book> books) async => null;

  @override
  Future<String?> pickFileText() async => '[{"name":"文件书单","author":"作者"}]';

  @override
  Future<String> resolveInput(
    String input, {
    required PublicTextFetchPort fetchPort,
  }) async => input;

  @override
  List<BookshelfListEntry> parseEntries(String text) => [
    (name: '文件书单', author: '作者', intro: ''),
  ];
}

void main() {
  testWidgets('uses the bookshelf list port for file selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ImportBookshelfDialog(listPort: _FakeBookshelfListPort()),
        ),
      ),
    );

    await tester.tap(find.text('选文件'));
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '[{"name":"文件书单","author":"作者"}]');
  });
}
