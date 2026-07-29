import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/annotation/bookmark_snapshot.dart';
import 'package:legado_flutter/domain/ports/bookmark_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/services/bookmark_service.dart';
import 'package:legado_flutter/widgets/bookmark_editor_sheet.dart';

void main() {
  late _MemoryBookmarkPort port;
  final book = Book(id: 'book-1', name: '测试书', author: '作者');

  setUp(() {
    port = _MemoryBookmarkPort();
    BookmarkService.configureBookmarkPort(port);
  });

  tearDown(() {
    BookmarkService.resetBookmarkPort();
  });

  testWidgets('canceling a new bookmark does not persist it', (tester) async {
    await tester.pumpWidget(_host(book));
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    expect(find.text('书签'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(port.list(), isEmpty);
  });

  testWidgets('saving an existing bookmark keeps identity and position', (
    tester,
  ) async {
    const existing = BookmarkSnapshot(
      time: 123,
      bookId: 'book-1',
      bookName: '测试书',
      bookAuthor: '作者',
      chapterIndex: 4,
      chapterPos: 88,
      chapterName: '第五章',
      bookText: '旧片段',
      content: '旧备注',
    );
    port.save(
      const BookmarkSnapshot(
        time: 123,
        bookId: 'book-1',
        bookName: '测试书',
        bookAuthor: '作者',
        chapterIndex: 4,
        chapterPos: 88,
        chapterName: '第五章',
        bookText: '旧片段',
        content: '旧备注',
      ),
    );

    await tester.pumpWidget(_host(book, existing: existing));
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '新片段');
    await tester.enterText(fields.at(1), '新备注');
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    final saved = port.list().single;
    expect(saved.time, 123);
    expect(saved.chapterIndex, 4);
    expect(saved.chapterPos, 88);
    expect(saved.chapterName, '第五章');
    expect(saved.bookText, '新片段');
    expect(saved.content, '新备注');
  });
}

Widget _host(Book book, {BookmarkSnapshot? existing}) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => FilledButton(
          onPressed: () {
            showBookmarkEditorSheet(
              context,
              book: book,
              existing: existing,
              chapterTitle: '第一章',
              chapterIndex: 1,
              chapterPos: 12,
              bookText: '新书签',
            );
          },
          child: const Text('打开'),
        ),
      ),
    ),
  );
}

class _MemoryBookmarkPort implements BookmarkPort {
  final Map<int, BookmarkSnapshot> _items = {};

  @override
  bool get isAvailable => true;

  @override
  List<BookmarkSnapshot> list({String? bookId}) => _items.values
      .where((item) => bookId == null || item.bookId == bookId)
      .toList(growable: false);

  @override
  bool save(BookmarkSnapshot bookmark) {
    _items[bookmark.time] = bookmark;
    return true;
  }

  @override
  bool delete(int time) => _items.remove(time) != null;
}
