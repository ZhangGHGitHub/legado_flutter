import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_config_dialog_port.dart';
import 'package:legado_flutter/features/bookshelf/bookshelf_config_dialog.dart';

final class _FakeBookshelfConfigDialogPort
    implements BookshelfConfigDialogPort {
  _FakeBookshelfConfigDialogPort(this.loaded);

  final BookshelfConfig loaded;
  BookshelfConfig? saved;

  @override
  Future<BookshelfConfig> load() async => loaded;

  @override
  Future<void> save(BookshelfConfig config) async {
    saved = config;
  }
}

Widget _host(BookshelfConfigDialogPort port, BookshelfConfig initial) {
  return MaterialApp(
    home: Scaffold(
      body: BookshelfConfigDialog(initial: initial, port: port),
    ),
  );
}

void main() {
  testWidgets('saves changed settings only after confirming', (tester) async {
    final port = _FakeBookshelfConfigDialogPort(const BookshelfConfig());
    await tester.pumpWidget(_host(port, const BookshelfConfig()));

    expect(port.saved, isNull);
    await tester.tap(find.byType(SwitchListTile).first);
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(port.saved, isNotNull);
    expect(port.saved!.showUnread, isFalse);
    expect(port.saved!.bookshelfLayout, 0);
    expect(port.saved!.bookshelfSort, 0);
    expect(port.saved!.bookGroupStyle, 0);
  });

  testWidgets('preserves all initial values when confirming without edits', (
    tester,
  ) async {
    const initial = BookshelfConfig(
      bookGroupStyle: 1,
      bookshelfLayout: 3,
      bookshelfSort: 5,
      showUnread: false,
      showLastUpdateTime: true,
      showWaitUpCount: true,
      showBookshelfFastScroller: true,
      onlyUpdateRead: true,
      showBookname: 2,
      bookshelfMargin: 36,
      bookOrder: ['book-2', 'book-1'],
    );
    final port = _FakeBookshelfConfigDialogPort(initial);
    await tester.pumpWidget(_host(port, initial));

    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    final saved = port.saved;
    expect(saved, isNotNull);
    expect(saved!.bookGroupStyle, initial.bookGroupStyle);
    expect(saved.bookshelfLayout, initial.bookshelfLayout);
    expect(saved.bookshelfSort, initial.bookshelfSort);
    expect(saved.showUnread, initial.showUnread);
    expect(saved.showLastUpdateTime, initial.showLastUpdateTime);
    expect(saved.showWaitUpCount, initial.showWaitUpCount);
    expect(saved.showBookshelfFastScroller, initial.showBookshelfFastScroller);
    expect(saved.onlyUpdateRead, initial.onlyUpdateRead);
    expect(saved.showBookname, initial.showBookname);
    expect(saved.bookshelfMargin, initial.bookshelfMargin);
    expect(saved.bookOrder, initial.bookOrder);
  });

  testWidgets('cancel does not save the edited configuration', (tester) async {
    final port = _FakeBookshelfConfigDialogPort(const BookshelfConfig());
    await tester.pumpWidget(_host(port, const BookshelfConfig()));

    await tester.tap(find.byType(SwitchListTile).first);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(port.saved, isNull);
  });
}
