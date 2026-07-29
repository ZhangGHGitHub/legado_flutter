import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:legado_flutter/features/bookshelf/bookshelf_arrange_page.dart';
import 'package:legado_flutter/database/dao/book_dao.dart';
import 'package:legado_flutter/database/dao/source_dao.dart';
import 'package:legado_flutter/infrastructure/cache/file_chapter_content_cache.dart';
import 'package:legado_flutter/infrastructure/engine/frb_book_source_validation_port.dart';
import 'package:legado_flutter/infrastructure/preferences/shared_preferences_book_group_prefs.dart';
import 'package:legado_flutter/providers/book_provider.dart';
import 'package:legado_flutter/providers/source_provider.dart';
import 'package:legado_flutter/services/book_group_store.dart';
import 'package:legado_flutter/services/bookshelf_arrange_prefs.dart';
import '../helpers/book_source_service_test_factory.dart';

class _FakeBookshelfArrangePrefs implements BookshelfArrangePrefsPort {
  bool value = false;
  int loadCount = 0;
  int saveCount = 0;

  @override
  Future<bool> loadOpenBookInfoByTitle() async {
    loadCount++;
    return value;
  }

  @override
  Future<void> saveOpenBookInfoByTitle(bool value) async {
    saveCount++;
    this.value = value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    BookGroupStore.configurePrefsPort(
      await SharedPreferencesBookGroupPrefs.load(),
    );
  });

  tearDown(BookGroupStore.resetPrefsPort);

  testWidgets('arrange page reads and writes the injected preference port', (
    tester,
  ) async {
    final preferences = _FakeBookshelfArrangePrefs();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => BookProvider(
              repository: BookDao(),
              contentCache: const FileChapterContentCache(),
              sourceService: createTestBookSourceService(),
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => SourceProvider(
              repository: SourceDao(),
              validationPort: FrbBookSourceValidationPort(),
              sourceService: createTestBookSourceService(),
            ),
          ),
        ],
        child: MaterialApp(
          home: BookshelfArrangePage(preferences: preferences),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(preferences.loadCount, 1);
    expect(find.text('没有书籍'), findsOneWidget);

    await tester.tap(find.byType(PopupMenuButton<String>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckedPopupMenuItem<String>));
    await tester.pumpAndSettle();

    expect(preferences.saveCount, 1);
    expect(preferences.value, isTrue);
  });

  test('SharedPreferences adapter preserves the established key', () async {
    SharedPreferences.setMockInitialValues({
      BookshelfArrangePrefsPort.openBookInfoByTitleKey: true,
    });
    const preferences = SharedPreferencesBookshelfArrangePrefs();

    expect(await preferences.loadOpenBookInfoByTitle(), isTrue);
    await preferences.saveOpenBookInfoByTitle(false);
    expect(await preferences.loadOpenBookInfoByTitle(), isFalse);
  });
}
