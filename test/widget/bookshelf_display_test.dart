import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_display_port.dart';
import 'package:legado_flutter/database/dao/book_dao.dart';
import 'package:legado_flutter/domain/book/book.dart' as domain;
import 'package:legado_flutter/features/bookshelf/bookshelf_page.dart';
import 'package:legado_flutter/features/bookshelf/bookshelf_style2_page.dart';
import 'package:legado_flutter/infrastructure/cache/file_chapter_content_cache.dart';
import 'package:legado_flutter/providers/book_provider.dart';
import '../helpers/book_source_service_test_factory.dart';

final class _FakeBookshelfDisplayPort implements BookshelfDisplayPort {
  @override
  Future<BookshelfConfig> loadConfig() async =>
      const BookshelfConfig(bookGroupStyle: 1);

  @override
  Future<List<String>> loadBookOrder() async => const [];

  @override
  List<domain.Book> sortBooks(
    List<domain.Book> books, {
    required int sortMode,
    required List<String> orderIds,
    Set<String> pinnedIds = const {},
  }) => [...books];
}

void main() {
  testWidgets('uses the caller display port to select the bookshelf style', (
    tester,
  ) async {
    final provider = BookProvider(
      repository: BookDao(),
      sourceService: createTestBookSourceService(),
      contentCache: const FileChapterContentCache(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider.value(
          value: provider,
          child: BookshelfPage(displayPort: _FakeBookshelfDisplayPort()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(BookshelfStyle2Page), findsOneWidget);
  });
}
