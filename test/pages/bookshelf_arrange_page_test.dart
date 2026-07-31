import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:legado_flutter/features/bookshelf/bookshelf_arrange_page.dart';
import 'package:legado_flutter/application/bookshelf/book_group_store_port.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_arrange_port.dart';
import 'package:legado_flutter/application/book/book_group_policy.dart';
import 'package:legado_flutter/database/dao/book_dao.dart';
import 'package:legado_flutter/domain/book/book_group.dart';
import 'package:legado_flutter/database/dao/source_dao.dart';
import 'package:legado_flutter/infrastructure/cache/file_chapter_content_cache.dart';
import 'package:legado_flutter/infrastructure/engine/frb_book_source_validation_port.dart';
import 'package:legado_flutter/infrastructure/bookshelf/bookshelf_arrange_port_adapter.dart';
import 'package:legado_flutter/providers/book_provider.dart';
import 'package:legado_flutter/providers/source_provider.dart';
import '../helpers/book_source_service_test_factory.dart';

class _FakeBookshelfArrangePrefs implements BookshelfArrangePort {
  bool value = false;
  int loadCount = 0;
  int saveCount = 0;
  int sortMode = 0;
  List<String> order = const [];

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

  @override
  Future<int> loadSortMode() async => sortMode;

  @override
  Future<List<String>> loadBookOrder() async => List.of(order);

  @override
  Future<void> saveBookOrder(List<String> ids) async => order = List.of(ids);

  @override
  Future<void> saveSortMode(int mode) async => sortMode = mode;
}

class _FakeBookGroupStore implements BookGroupStorePort {
  @override
  List<BookGroup> cached = BookGroupPolicy.defaultSystemGroups();

  @override
  Future<void> syncNamesFromBooks(Iterable<String> names) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('arrange page reads and writes the injected preference port', (
    tester,
  ) async {
    final preferences = _FakeBookshelfArrangePrefs();
    final groupStore = _FakeBookGroupStore();

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
          home: BookshelfArrangePage(
            preferences: preferences,
            groupStore: groupStore,
          ),
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
      BookshelfArrangePort.openBookInfoByTitleKey: true,
    });
    const preferences = SharedPreferencesBookshelfArrangePortAdapter();

    expect(await preferences.loadOpenBookInfoByTitle(), isTrue);
    await preferences.saveOpenBookInfoByTitle(false);
    expect(await preferences.loadOpenBookInfoByTitle(), isFalse);
  });
}
