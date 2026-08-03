import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:legado_flutter/features/bookshelf/bookshelf_arrange_page.dart';
import 'package:legado_flutter/application/bookshelf/book_group_management_port.dart';
import 'package:legado_flutter/application/bookshelf/book_group_store_port.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_arrange_port.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_arrange_group_command_port.dart';
import 'package:legado_flutter/application/book/book_group_policy.dart';
import 'package:legado_flutter/database/dao/book_dao.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/domain/book/book_group.dart';
import 'package:legado_flutter/database/dao/source_dao.dart';
import 'package:legado_flutter/domain/repositories/book_repository.dart';
import 'package:legado_flutter/domain/repositories/book_source_repository.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
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

class _FakeGroupCommands implements BookshelfArrangeGroupCommandPort {
  final singleCalls = <(String, String)>[];
  final batchCalls = <(List<String>, String)>[];
  List<Book> snapshot = const [];
  Object? error;

  @override
  Future<List<Book>> updateBookGroup(String bookId, String group) async {
    singleCalls.add((bookId, group));
    if (error case final error?) throw error;
    return List<Book>.unmodifiable(snapshot);
  }

  @override
  Future<List<Book>> updateBooksGroup(
    Iterable<String> bookIds,
    String group,
  ) async {
    batchCalls.add((List<String>.of(bookIds), group));
    if (error case final error?) throw error;
    return List<Book>.unmodifiable(snapshot);
  }
}

class _FakeBookGroupManagementPort implements BookGroupManagementPort {
  List<BookGroup> selectGroups = const [];

  @override
  Future<bool> canAddGroup() async => true;

  @override
  Future<void> delete(BookGroup group) async {}

  @override
  Future<List<BookGroup>> load() async => const [];

  @override
  Future<List<BookGroup>> loadSelectGroups() async => List.of(selectGroups);

  @override
  Future<int> maxOrder() async => 0;

  @override
  Future<void> syncNamesFromBooks(Iterable<String> names) async {}

  @override
  Future<int> unusedId() async => 1;

  @override
  Future<void> update(BookGroup group) async {}
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
            groupCommands: _FakeGroupCommands(),
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

  testWidgets('arrange page reads source labels from the shared controller', (
    tester,
  ) async {
    final source = BookSource(
      bookSourceUrl: 'https://source.example',
      bookSourceName: '共享书源',
    );
    final sourceRepository = _MemoryBookSourceRepository([source]);
    final sourceProvider = SourceProvider(
      repository: sourceRepository,
      validationPort: FrbBookSourceValidationPort(),
      sourceService: createTestBookSourceService(),
    );
    await sourceProvider.loadSources();

    final bookProvider = BookProvider(
      repository: _MemoryBookRepository(),
      contentCache: const FileChapterContentCache(),
      sourceService: createTestBookSourceService(),
    );
    await bookProvider.addBook(
      Book(
        id: 'https://source.example/book-1',
        name: '测试书',
        author: '作者',
        sourceUrl: 'https://source.example/book-1',
        bookSourceUrl: source.bookSourceUrl,
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BookProvider>.value(value: bookProvider),
          ChangeNotifierProvider<SourceProvider>.value(value: sourceProvider),
        ],
        child: MaterialApp(
          home: BookshelfArrangePage(
            preferences: _FakeBookshelfArrangePrefs(),
            groupStore: _FakeBookGroupStore(),
            groupCommands: _FakeGroupCommands(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('共享书源'), findsOneWidget);

    await sourceProvider.updateSource(
      source.copyWith(bookSourceName: '更新后的书源'),
    );
    await tester.pumpAndSettle();

    expect(find.text('更新后的书源'), findsOneWidget);
  });

  testWidgets('batch move uses the command snapshot and clears selection', (
    tester,
  ) async {
    final bookProvider = await _bookProviderWith([
      const Book(id: 'one', name: '第一本'),
      const Book(id: 'two', name: '第二本'),
    ]);
    final commands = _FakeGroupCommands()
      ..snapshot = const [
        Book(id: 'one', name: '快照第一本', group: '目标分组'),
        Book(id: 'two', name: '快照第二本', group: '目标分组'),
      ];

    await _pumpArrangePage(tester, bookProvider, commands);
    await tester.tap(find.text('第二本'));
    await tester.tap(find.text('第一本'));
    await tester.pump();

    expect(find.text('全选 (2/2)'), findsOneWidget);
    await tester.tap(find.text('移入分组'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();

    expect(commands.batchCalls, hasLength(1));
    expect(commands.batchCalls.single.$1, ['two', 'one']);
    expect(commands.batchCalls.single.$2, '目标分组');
    expect(commands.singleCalls, isEmpty);
    expect(find.text('快照第一本'), findsOneWidget);
    expect(find.text('快照第二本'), findsOneWidget);
    expect(find.text('第一本'), findsNothing);
    expect(find.text('第二本'), findsNothing);
    expect(find.text('全选 (0/2)'), findsOneWidget);
    expect(bookProvider.books.map((book) => book.name), ['第一本', '第二本']);
  });

  testWidgets('inline group command uses the selected book and snapshot', (
    tester,
  ) async {
    final bookProvider = await _bookProviderWith([
      const Book(id: 'one', name: '第一本'),
    ]);
    final commands = _FakeGroupCommands()
      ..snapshot = const [Book(id: 'one', name: '单本快照', group: '目标分组')];

    await _pumpArrangePage(tester, bookProvider, commands);
    await tester.tap(find.text('分组'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();

    expect(commands.singleCalls, [('one', '目标分组')]);
    expect(commands.batchCalls, isEmpty);
    expect(find.text('单本快照'), findsOneWidget);
    expect(find.text('第一本'), findsNothing);
  });

  testWidgets('add to group menu routes the selected ids through the command', (
    tester,
  ) async {
    final bookProvider = await _bookProviderWith([
      const Book(id: 'one', name: '第一本'),
      const Book(id: 'two', name: '第二本'),
    ]);
    final commands = _FakeGroupCommands()
      ..snapshot = const [
        Book(id: 'one', name: '加入后第一本', group: '目标分组'),
        Book(id: 'two', name: '第二本'),
      ];

    await _pumpArrangePage(tester, bookProvider, commands);
    await tester.tap(find.text('第一本'));
    await tester.pump();
    await tester.tap(find.widgetWithIcon(IconButton, Icons.more_vert).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('加入分组'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();

    expect(commands.batchCalls, hasLength(1));
    expect(commands.batchCalls.single.$1, ['one']);
    expect(commands.batchCalls.single.$2, '目标分组');
    expect(commands.singleCalls, isEmpty);
    expect(find.text('加入后第一本'), findsOneWidget);
    expect(find.text('全选 (0/2)'), findsOneWidget);
  });

  testWidgets('batch move failure preserves the list and selection', (
    tester,
  ) async {
    final bookProvider = await _bookProviderWith([
      const Book(id: 'one', name: '第一本'),
      const Book(id: 'two', name: '第二本'),
    ]);
    final failure = StateError('分组写入失败');
    final commands = _FakeGroupCommands()
      ..snapshot = const [Book(id: 'one', name: '不应显示')]
      ..error = failure;

    Object? reportedError;
    await runZonedGuarded(() async {
      await _pumpArrangePage(tester, bookProvider, commands);
      await tester.tap(find.text('第一本'));
      await tester.pump();

      await tester.tap(find.text('移入分组'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CheckboxListTile));
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();
    }, (error, _) => reportedError = error);

    expect(reportedError, same(failure));

    expect(commands.batchCalls, hasLength(1));
    expect(commands.batchCalls.single.$1, ['one']);
    expect(commands.batchCalls.single.$2, '目标分组');
    expect(commands.singleCalls, isEmpty);
    expect(find.text('第一本'), findsOneWidget);
    expect(find.text('第二本'), findsOneWidget);
    expect(find.text('不应显示'), findsNothing);
    expect(find.text('全选 (1/2)'), findsOneWidget);
  });

  testWidgets('manual reorder does not mutate BookProvider books', (
    tester,
  ) async {
    final sourceProvider = SourceProvider(
      repository: _MemoryBookSourceRepository(const []),
      validationPort: FrbBookSourceValidationPort(),
      sourceService: createTestBookSourceService(),
    );
    final bookProvider = BookProvider(
      repository: _MemoryBookRepository(),
      contentCache: const FileChapterContentCache(),
      sourceService: createTestBookSourceService(),
    );
    await bookProvider.addBook(const Book(id: 'one', name: '第一本'));
    await bookProvider.addBook(const Book(id: 'two', name: '第二本'));
    final preferences = _FakeBookshelfArrangePrefs()..sortMode = 3;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BookProvider>.value(value: bookProvider),
          ChangeNotifierProvider<SourceProvider>.value(value: sourceProvider),
        ],
        child: MaterialApp(
          home: BookshelfArrangePage(
            preferences: preferences,
            groupStore: _FakeBookGroupStore(),
            groupCommands: _FakeGroupCommands(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(bookProvider.books.map((book) => book.id), ['one', 'two']);
    await tester.drag(
      find.byIcon(Icons.drag_handle).first,
      const Offset(0, 160),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('第一本')).dy,
      greaterThan(tester.getTopLeft(find.text('第二本')).dy),
    );
    expect(bookProvider.books.map((book) => book.id), ['one', 'two']);
    expect(find.text('第一本'), findsOneWidget);
    expect(find.text('第二本'), findsOneWidget);
  });
}

Future<BookProvider> _bookProviderWith(Iterable<Book> books) async {
  final provider = BookProvider(
    repository: _MemoryBookRepository(),
    contentCache: const FileChapterContentCache(),
    sourceService: createTestBookSourceService(),
  );
  for (final book in books) {
    await provider.addBook(book);
  }
  return provider;
}

Future<void> _pumpArrangePage(
  WidgetTester tester,
  BookProvider bookProvider,
  _FakeGroupCommands commands,
) async {
  final groupManagement = _FakeBookGroupManagementPort()
    ..selectGroups = const [BookGroup(groupId: 1, groupName: '目标分组', order: 1)];
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<BookProvider>.value(value: bookProvider),
        ChangeNotifierProvider(
          create: (_) => SourceProvider(
            repository: _MemoryBookSourceRepository(const []),
            validationPort: FrbBookSourceValidationPort(),
            sourceService: createTestBookSourceService(),
          ),
        ),
        Provider<BookGroupManagementPort>.value(value: groupManagement),
      ],
      child: MaterialApp(
        home: BookshelfArrangePage(
          preferences: _FakeBookshelfArrangePrefs(),
          groupStore: _FakeBookGroupStore(),
          groupCommands: commands,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final class _MemoryBookSourceRepository implements BookSourceRepository {
  _MemoryBookSourceRepository(Iterable<BookSource> initial)
    : sources = List<BookSource>.of(initial);

  final List<BookSource> sources;

  @override
  Future<void> upsert(BookSource source) async {
    await update(source);
  }

  @override
  Future<void> upsertAll(List<BookSource> values) async {
    for (final source in values) {
      await update(source);
    }
  }

  @override
  Future<void> update(BookSource source) async {
    final index = sources.indexWhere(
      (value) => value.bookSourceUrl == source.bookSourceUrl,
    );
    if (index < 0) {
      sources.add(source);
    } else {
      sources[index] = source;
    }
  }

  @override
  Future<List<BookSource>> getAll() async => List.unmodifiable(sources);

  @override
  Future<List<BookSource>> getEnabled() async =>
      sources.where((source) => source.enabled).toList();

  @override
  Future<void> toggle(String url, bool enabled) async {
    final source = sources.firstWhere((value) => value.bookSourceUrl == url);
    await update(source.copyWith(enabled: enabled));
  }

  @override
  Future<void> delete(String url) async {
    sources.removeWhere((source) => source.bookSourceUrl == url);
  }
}

final class _MemoryBookRepository implements BookRepository {
  final books = <String, Book>{};

  @override
  Future<void> insert(Book book) async => books[book.id] = book;

  @override
  Future<List<Book>> getAll() async => List.unmodifiable(books.values);

  @override
  Future<void> updateProgress(
    String bookId,
    double progress,
    String? chapter, {
    int pageIndex = 0,
  }) async {}

  @override
  Future<void> delete(String bookId) async => books.remove(bookId);

  @override
  Future<void> updateCover(String bookId, String coverUrl) async {}

  @override
  Future<void> updateBookDetails(
    String bookId,
    String name,
    String author,
    String description,
  ) async {}

  @override
  Future<void> updateGroup(String bookId, String group) async {
    final book = books[bookId];
    if (book != null) books[bookId] = book.copyWith(group: group);
  }

  @override
  Future<void> insertChapters(List<Chapter> chapters) async {}

  @override
  Future<List<Chapter>> getChapters(String bookId) async => const [];

  @override
  Future<String?> getChapterContent(String chapterId) async => null;

  @override
  Future<void> saveChapterContent(String chapterId, String content) async {}

  @override
  Future<void> clearChapterContent(Chapter chapter) async {}
}
