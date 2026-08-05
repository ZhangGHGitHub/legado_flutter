import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/bookshelf/shelf_unread_meta_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/widgets/shelf_unread_badge.dart';
import 'package:provider/provider.dart';

final class _FakeShelfUnreadMetaPort extends ChangeNotifier
    implements ShelfUnreadMetaPort {
  ({int count, int? durIndex})? metadata;

  @override
  ({int count, int? durIndex})? metaFor(String bookId) => metadata;
}

Book _book({int durChapterIndex = 0, String? currentChapter = '第1章'}) => Book(
  id: 'book-1',
  name: '测试书',
  currentChapter: currentChapter,
  lastChapter: '第10章',
  durChapterIndex: durChapterIndex,
);

Widget _host({required ShelfUnreadMetaPort port, required Book book}) {
  return MaterialApp(
    home: Scaffold(
      body: ListenableProvider<ShelfUnreadMetaPort>.value(
        value: port,
        child: ShelfUnreadBadge(book: book),
      ),
    ),
  );
}

void main() {
  testWidgets('renders unread count and updates after metadata changes', (
    tester,
  ) async {
    final port = _FakeShelfUnreadMetaPort()
      ..metadata = (count: 10, durIndex: 2);
    await tester.pumpWidget(_host(port: port, book: _book()));

    expect(find.text('7'), findsOneWidget);

    port.metadata = (count: 1001, durIndex: 0);
    port.notifyListeners();
    await tester.pump();
    expect(find.text('999+'), findsOneWidget);
  });

  testWidgets('renders update label when only title changed', (tester) async {
    final port = _FakeShelfUnreadMetaPort()..metadata = (count: 5, durIndex: 4);
    await tester.pumpWidget(
      _host(
        port: port,
        book: _book(currentChapter: '第5章'),
      ),
    );

    expect(find.text('更新'), findsOneWidget);
  });

  testWidgets('hides badge when unread and update state are absent', (
    tester,
  ) async {
    final port = _FakeShelfUnreadMetaPort()..metadata = (count: 5, durIndex: 4);
    final book = _book(currentChapter: '第10章').copyWith(lastChapter: '第10章');
    await tester.pumpWidget(_host(port: port, book: book));

    expect(find.text('更新'), findsNothing);
    expect(find.text('999+'), findsNothing);
  });

  testWidgets('uses the empty port when an independent host omits the port', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ShelfUnreadBadge(book: _book())),
      ),
    );

    expect(find.text('9'), findsOneWidget);
  });
}
