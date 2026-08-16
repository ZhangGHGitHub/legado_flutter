import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:legado_flutter/application/bookshelf/bookshelf_arrange_snapshot_port.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_list_port.dart';
import 'package:legado_flutter/application/diagnostics/app_log_port.dart';
import 'package:legado_flutter/application/reader/reader_font_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/diagnostics/diagnostic_record.dart';
import 'package:legado_flutter/domain/ports/public_text_fetch_port.dart';
import '../../helpers/fake_reader_font_port.dart';
import 'package:legado_flutter/features/bookshelf/bookshelf_overflow_menu.dart';
import 'package:legado_flutter/features/bookshelf/bookshelf_menu_actions.dart';

class _FakeReaderFontPort extends FakeReaderFontPort {
  @override
  String platformSansFamily() => 'Test Sans';

  @override
  List<String> cjkFallbackFamilies() => const [
    'CJK Primary',
    'CJK Secondary',
    'sans-serif',
  ];
}

final class _FakeSnapshotPort implements BookshelfArrangeSnapshotPort {
  const _FakeSnapshotPort(this.books);

  @override
  final List<Book> books;
}

final class _RecordingListPort implements BookshelfListPort {
  List<Book>? exported;

  @override
  Future<String?> exportBooks(List<Book> books) async {
    exported = List<Book>.of(books);
    return 'books.json';
  }

  @override
  Future<String?> pickFileText() async => throw UnimplementedError();

  @override
  Future<String> resolveInput(
    String input, {
    required PublicTextFetchPort fetchPort,
  }) async => throw UnimplementedError();

  @override
  List<BookshelfListEntry> parseEntries(String text) =>
      throw UnimplementedError();
}

final class _FakeAppLog implements AppLogPort {
  const _FakeAppLog();

  @override
  List<DiagnosticRecord> get entries => const [];

  @override
  Future<void> ensureLoaded() async {}

  @override
  Future<void> i(
    String message, {
    String category = 'app',
    String? source,
    Map<String, String> metadata = const {},
  }) async {}

  @override
  Future<void> w(
    String message, {
    String category = 'app',
    String? source,
    Map<String, String> metadata = const {},
  }) async {}

  @override
  Future<void> e(
    String message, {
    String category = 'app',
    String? source,
    Map<String, String> metadata = const {},
  }) async {}

  @override
  Future<void> clear() async {}

  @override
  String exportText() => '';
}

void main() {
  Future<void> pumpMenu(WidgetTester tester) async {
    await tester.pumpWidget(
      Provider<ReaderFontPort>.value(
        value: _FakeReaderFontPort(),
        child: MaterialApp(
          home: Scaffold(
            body: PopupMenuButton<String>(
              itemBuilder: BookshelfOverflowMenu.items,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
  }

  testWidgets('menu uses the injected reader font contract', (tester) async {
    await pumpMenu(tester);

    final label = tester.widget<Text>(find.text('更新目录'));
    expect(label.style?.fontFamily, 'Test Sans');
    expect(label.style?.fontFamilyFallback, [
      'CJK Primary',
      'CJK Secondary',
      'sans-serif',
    ]);
  });

  testWidgets('menu keeps the established action order and labels', (
    tester,
  ) async {
    await pumpMenu(tester);

    final values = tester
        .widgetList<PopupMenuItem<String>>(find.byType(PopupMenuItem<String>))
        .map((item) => item.value)
        .toList();
    expect(values, [
      BookshelfOverflowMenu.updateToc,
      BookshelfOverflowMenu.addLocal,
      BookshelfOverflowMenu.remoteBook,
      BookshelfOverflowMenu.addUrl,
      BookshelfOverflowMenu.arrange,
      BookshelfOverflowMenu.cacheExport,
      BookshelfOverflowMenu.groupMgmt,
      BookshelfOverflowMenu.layout,
      BookshelfOverflowMenu.exportList,
      BookshelfOverflowMenu.importList,
      BookshelfOverflowMenu.log,
    ]);
    expect(find.text('添加网址'), findsOneWidget);
    expect(find.text('导出书单'), findsOneWidget);
    expect(find.text('导入书单'), findsOneWidget);
    expect(find.text('日志'), findsOneWidget);
  });

  testWidgets('export list uses the injected complete bookshelf snapshot', (
    tester,
  ) async {
    final listPort = _RecordingListPort();
    const books = [Book(id: 'one', name: '第一本')];
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<BookshelfArrangeSnapshotPort>.value(
            value: const _FakeSnapshotPort(books),
          ),
          Provider<BookshelfListPort>.value(value: listPort),
          Provider<AppLogPort>.value(value: const _FakeAppLog()),
        ],
        child: const MaterialApp(home: Scaffold()),
      ),
    );

    await BookshelfMenuActions.handle(
      tester.element(find.byType(Scaffold)),
      BookshelfOverflowMenu.exportList,
    );

    expect(listPort.exported, books);
  });
}
