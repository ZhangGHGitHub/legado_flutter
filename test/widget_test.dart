import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:legado_flutter/application/preferences/bookshelf_display_prefs_port.dart';
import 'package:legado_flutter/database/dao/book_dao.dart';
import 'package:legado_flutter/features/bookshelf/bookshelf_page.dart';
import 'package:legado_flutter/infrastructure/cache/file_chapter_content_cache.dart';
import 'package:legado_flutter/providers/book_provider.dart';
import 'helpers/book_source_service_test_factory.dart';

void main() {
  SharedPreferences.setMockInitialValues({});

  testWidgets('BookshelfPage shows empty state', (WidgetTester tester) async {
    final bookProvider = BookProvider(
      repository: BookDao(),
      sourceService: createTestBookSourceService(),
      contentCache: const FileChapterContentCache(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: bookProvider),
            Provider<BookshelfDisplayPrefsPort>.value(
              value: _FakeBookshelfDisplayPrefsPort(),
            ),
          ],
          child: const BookshelfPage(),
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
