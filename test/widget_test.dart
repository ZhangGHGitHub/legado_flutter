import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:legado_flutter/application/preferences/bookshelf_display_prefs_port.dart';
import 'package:legado_flutter/application/bookshelf/book_group_store_port.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_local_book_port.dart';
import 'package:legado_flutter/database/dao/book_dao.dart';
import 'package:legado_flutter/domain/book/book_group.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/features/bookshelf/bookshelf_page.dart';
import 'package:legado_flutter/infrastructure/cache/file_chapter_content_cache.dart';
import 'package:legado_flutter/providers/book_provider.dart';
import 'package:legado_flutter/providers/source_provider.dart';
import 'package:legado_flutter/application/source_management/source_notifier.dart';
import 'helpers/book_source_service_test_factory.dart';
import 'application/source_management/source_controller_test.dart'
    as source_fixtures;

void main() {
  SharedPreferences.setMockInitialValues({});

  testWidgets('BookshelfPage shows empty state', (WidgetTester tester) async {
    final bookProvider = BookProvider(
      repository: BookDao(),
      sourceService: createTestBookSourceService(),
      contentCache: const FileChapterContentCache(),
    );
    final sourceProvider = SourceProvider(
      repository: source_fixtures.createRepositoryForNotifierTest(),
      validationPort: source_fixtures.createValidationPortForNotifierTest(),
      sourceService: source_fixtures.createSourceServiceForNotifierTest(),
    );
    addTearDown(sourceProvider.dispose);
    await sourceProvider.loadSources();

    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          sourceControllerProvider.overrideWithValue(sourceProvider.controller),
        ],
        child: MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: bookProvider),
              ChangeNotifierProvider.value(value: sourceProvider),
              Provider<BookshelfDisplayPrefsPort>.value(
                value: _FakeBookshelfDisplayPrefsPort(),
              ),
              Provider<BookGroupStorePort>.value(
                value: _FakeBookGroupStorePort(),
              ),
              Provider<BookshelfLocalBookPort>.value(
                value: _FakeBookshelfLocalBookPort(),
              ),
            ],
            child: const BookshelfPage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('书架空空如也'), findsOneWidget);
  });
}

class _FakeBookshelfDisplayPrefsPort implements BookshelfDisplayPrefsPort {
  @override
  Future<BookshelfDisplayPrefs> load() async => const BookshelfDisplayPrefs();

  @override
  Future<bool> saveGrouped(bool value) async => true;

  @override
  Future<bool> savePinned(Iterable<String> ids) async => true;
}

class _FakeBookGroupStorePort implements BookGroupStorePort {
  @override
  List<BookGroup> get cached => const [];

  @override
  Future<void> syncNamesFromBooks(Iterable<String> names) async {}
}

class _FakeBookshelfLocalBookPort implements BookshelfLocalBookPort {
  @override
  Future<Book?> importLocalBook() async => null;
}
