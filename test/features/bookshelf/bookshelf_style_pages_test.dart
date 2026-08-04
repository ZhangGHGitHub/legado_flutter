import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/bookshelf/book_group_store_port.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_arrange_delete_command_port.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_arrange_group_command_port.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_notifier.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_display_port.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_local_book_port.dart';
import 'package:legado_flutter/application/preferences/bookshelf_display_prefs_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/book_group.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/domain/ports/chapter_content_cache_port.dart';
import 'package:legado_flutter/domain/repositories/book_repository.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/features/bookshelf/bookshelf_style1_page.dart';
import 'package:legado_flutter/features/bookshelf/bookshelf_style2_page.dart';
import 'package:legado_flutter/infrastructure/bookshelf/bookshelf_arrange_delete_command_port_adapter.dart';
import 'package:legado_flutter/infrastructure/bookshelf/bookshelf_arrange_group_command_port_adapter.dart';
import 'package:legado_flutter/application/source_management/source_notifier.dart';
import 'package:legado_flutter/providers/book_provider.dart';
import 'package:legado_flutter/providers/source_provider.dart';
import 'package:provider/provider.dart';

import '../../application/source_management/source_controller_test.dart'
    as source_fixtures;
import '../../helpers/book_source_service_test_factory.dart';

void main() {
  for (final style in _styles) {
    testWidgets('${style.name} renders the BookshelfState loading state', (
      tester,
    ) async {
      final provider = _BookshelfStateBookProvider(BookshelfState.loading());
      await _pumpStyle(tester, style, provider, settle: false);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
      '${style.name} renders an error and retries through the provider',
      (tester) async {
        final provider = _BookshelfStateBookProvider(
          BookshelfState.failure(StateError('数据库不可用'), StackTrace.current),
        );
        final notifier = _BookshelfStateNotifier(provider);
        await _pumpStyle(tester, style, provider, notifier: notifier);

        expect(find.text('加载失败'), findsOneWidget);
        expect(find.text('Bad state: 数据库不可用'), findsOneWidget);

        await tester.tap(find.text('重试'));
        await tester.pump();

        expect(provider.loadCalls, 1);
        expect(notifier.loadCalls, 0);
        expect(find.text('书架空空如也'), findsOneWidget);
      },
    );

    testWidgets('${style.name} shows provider loading while retrying', (
      tester,
    ) async {
      final provider = _BookshelfStateBookProvider(
        BookshelfState.failure(StateError('数据库不可用'), StackTrace.current),
      )..loadGate = Completer<void>();
      final notifier = _BookshelfStateNotifier(provider);
      await _pumpStyle(tester, style, provider, notifier: notifier);

      await tester.tap(find.text('重试'));
      await tester.pump();

      expect(provider.isLoading, isTrue);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(notifier.loadCalls, 0);

      provider.loadGate!.complete();
      await tester.pump();
      expect(find.text('书架空空如也'), findsOneWidget);
    });

    testWidgets('${style.name} renders an empty successful snapshot', (
      tester,
    ) async {
      await _pumpStyle(
        tester,
        style,
        _BookshelfStateBookProvider(BookshelfState.success(const [])),
      );

      expect(find.text('书架空空如也'), findsOneWidget);
    });

    testWidgets(
      '${style.name} rebuilds from an external BookshelfState snapshot',
      (tester) async {
        final oldBook = _book(_source()).copyWith(name: '旧书');
        final newBook = _book(_source()).copyWith(id: 'book-2', name: '外部快照书');
        final provider = _BookshelfStateBookProvider(
          BookshelfState.success([oldBook]),
        );
        final notifier = _BookshelfStateNotifier(provider);
        await _pumpStyle(tester, style, provider, notifier: notifier);

        expect(find.text('旧书'), findsOneWidget);
        notifier.publish(BookshelfState.success([newBook]));
        await tester.pump();

        expect(find.text('旧书'), findsNothing);
        expect(find.text('外部快照书'), findsOneWidget);
      },
    );

    testWidgets('${style.name} keeps toc refresh and writes on BookProvider', (
      tester,
    ) async {
      final source = _source();
      final book = _book(source);
      final sourceProvider = await _createSourceProvider(source);
      final provider = _BookshelfStateBookProvider(
        BookshelfState.success([book]),
      );
      addTearDown(sourceProvider.dispose);
      if (style == _BookshelfStyle.style1) {
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(640, 1000);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
      }

      await tester.pumpWidget(
        _host(
          sourceProvider: sourceProvider,
          bookProvider: provider,
          child: _stylePage(style),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('刷新'));
      await tester.pumpAndSettle();
      expect(provider.refreshCalls, 1);
      expect(provider.resolvedSource, same(source));

      await tester.longPress(find.text(book.name));
      await tester.pumpAndSettle();
      if (style == _BookshelfStyle.style1) {
        await tester.tap(find.text('移除'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, '移除'));
      } else {
        await tester.tap(find.widgetWithText(FilledButton, '移除'));
      }
      await tester.pumpAndSettle();

      expect(provider.removedBookId, book.id);
    });
  }

  testWidgets('style1 uses the shared SourceController resolver', (
    tester,
  ) async {
    final source = _source();
    final sourceProvider = await _createSourceProvider(source);
    final bookProvider = _RecordingBookProvider(_book(source));
    addTearDown(sourceProvider.dispose);

    await tester.pumpWidget(
      _host(
        sourceProvider: sourceProvider,
        bookProvider: bookProvider,
        child: BookshelfStyle1Page(config: const BookshelfConfig()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('刷新'));
    await tester.pumpAndSettle();

    expect(bookProvider.resolvedSource, same(source));
  });

  testWidgets('style2 uses the shared SourceController resolver', (
    tester,
  ) async {
    final source = _source();
    final sourceProvider = await _createSourceProvider(source);
    final bookProvider = _RecordingBookProvider(_book(source));
    addTearDown(sourceProvider.dispose);

    await tester.pumpWidget(
      _host(
        sourceProvider: sourceProvider,
        bookProvider: bookProvider,
        child: BookshelfStyle2Page(config: const BookshelfConfig()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('刷新'));
    await tester.pumpAndSettle();

    expect(bookProvider.resolvedSource, same(source));
  });
}

enum _BookshelfStyle { style1, style2 }

const _styles = _BookshelfStyle.values;

String _styleName(_BookshelfStyle style) => switch (style) {
  _BookshelfStyle.style1 => 'style1',
  _BookshelfStyle.style2 => 'style2',
};

extension on _BookshelfStyle {
  String get name => _styleName(this);
}

Widget _stylePage(_BookshelfStyle style) => switch (style) {
  _BookshelfStyle.style1 => const BookshelfStyle1Page(
    config: BookshelfConfig(),
  ),
  _BookshelfStyle.style2 => const BookshelfStyle2Page(
    config: BookshelfConfig(),
  ),
};

Future<void> _pumpStyle(
  WidgetTester tester,
  _BookshelfStyle style,
  _BookshelfStateBookProvider bookProvider, {
  _BookshelfStateNotifier? notifier,
  bool settle = true,
}) async {
  final sourceProvider = await _createSourceProvider(_source());
  addTearDown(sourceProvider.dispose);
  await tester.pumpWidget(
    _host(
      sourceProvider: sourceProvider,
      bookProvider: bookProvider,
      bookshelfNotifier: notifier,
      child: _stylePage(style),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

BookSource _source() => const BookSource(
  bookSourceUrl: 'https://source.example',
  bookSourceName: '共享书源',
);

Book _book(BookSource source) => Book(
  id: 'book-1',
  name: '测试书',
  author: '测试作者',
  sourceUrl: 'https://source.example/book/1',
  bookSourceUrl: source.bookSourceUrl,
);

Future<SourceProvider> _createSourceProvider(BookSource source) async {
  final repository = source_fixtures.createRepositoryForNotifierTest();
  await repository.upsert(source);
  final provider = SourceProvider(
    repository: repository,
    validationPort: source_fixtures.createValidationPortForNotifierTest(),
    sourceService: source_fixtures.createSourceServiceForNotifierTest(),
  );
  await provider.loadSources();
  return provider;
}

Widget _host({
  required SourceProvider sourceProvider,
  required BookProvider bookProvider,
  _BookshelfStateNotifier? bookshelfNotifier,
  required Widget child,
}) {
  final notifier =
      bookshelfNotifier ??
      (bookProvider is _BookshelfStateBookProvider
          ? _BookshelfStateNotifier(bookProvider)
          : _BookshelfStateNotifier(
              _BookshelfStateBookProvider(
                BookshelfState.success(bookProvider.books),
              ),
            ));
  return riverpod.ProviderScope(
    overrides: [
      sourceControllerProvider.overrideWithValue(sourceProvider.controller),
      bookshelfNotifierProvider.overrideWith(() => notifier),
    ],
    child: MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<SourceProvider>.value(value: sourceProvider),
          ChangeNotifierProvider<BookProvider>.value(value: bookProvider),
          Provider<BookshelfArrangeDeleteCommandPort>.value(
            value: BookshelfArrangeDeleteCommandPortAdapter(
              removeBook: bookProvider.removeBook,
              removeBooks: bookProvider.removeBooks,
            ),
          ),
          Provider<BookshelfArrangeGroupCommandPort>.value(
            value: BookshelfArrangeGroupCommandPortAdapter(
              updateBookGroup: bookProvider.updateBookGroup,
              updateBooksGroup: bookProvider.updateBooksGroup,
              books: () => bookProvider.books,
            ),
          ),
          Provider<BookshelfDisplayPrefsPort>.value(
            value: const _FakeBookshelfDisplayPrefsPort(),
          ),
          Provider<BookGroupStorePort>.value(
            value: const _FakeBookGroupStore(),
          ),
          Provider<BookshelfLocalBookPort>.value(
            value: const _FakeBookshelfLocalBookPort(),
          ),
        ],
        child: child,
      ),
    ),
  );
}

final class _RecordingBookProvider extends BookProvider {
  _RecordingBookProvider(this.book)
    : super(
        repository: _FakeBookRepository(),
        sourceService: createTestBookSourceService(),
        contentCache: const _FakeChapterContentCache(),
      );

  final Book book;
  BookSource? resolvedSource;

  @override
  List<Book> get books => [book];

  @override
  bool get isLoading => false;

  @override
  String? get loadError => null;

  @override
  bool get isShelfUpdateRunning => false;

  @override
  bool isBookShelfUpdating(String bookId) => false;

  @override
  Future<ShelfTocUpdateResult> refreshShelfToc(
    Iterable<Book> books, {
    required BookSource? Function(Book book) resolveSource,
    bool onlyUpdateRead = false,
    int concurrency = 3,
  }) async {
    resolvedSource = resolveSource(book);
    return const ShelfTocUpdateResult(
      requested: 1,
      eligible: 1,
      updated: 1,
      failed: 0,
      skipped: 0,
    );
  }
}

final class _BookshelfStateBookProvider extends BookProvider {
  _BookshelfStateBookProvider(this.snapshot)
    : super(
        repository: _FakeBookRepository(),
        sourceService: createTestBookSourceService(),
        contentCache: const _FakeChapterContentCache(),
      );

  BookshelfState snapshot;
  int loadCalls = 0;
  int refreshCalls = 0;
  BookSource? resolvedSource;
  String? removedBookId;
  VoidCallback? onSnapshotChanged;
  Completer<void>? loadGate;

  @override
  List<Book> get books => snapshot.books;

  @override
  bool get isLoading => snapshot.isLoading;

  @override
  String? get loadError => snapshot.hasError ? snapshot.error.toString() : null;

  @override
  bool get isShelfUpdateRunning => false;

  @override
  bool isBookShelfUpdating(String bookId) => false;

  void publish(BookshelfState next) {
    snapshot = next;
    notifyListeners();
  }

  @override
  Future<void> loadBooks({bool runMaintenance = true}) async {
    loadCalls++;
    publish(BookshelfState.loading(books: snapshot.books));
    final gate = loadGate;
    if (gate != null) await gate.future;
    publish(BookshelfState.success(snapshot.books));
    onSnapshotChanged?.call();
  }

  @override
  Future<ShelfTocUpdateResult> refreshShelfToc(
    Iterable<Book> books, {
    required BookSource? Function(Book book) resolveSource,
    bool onlyUpdateRead = false,
    int concurrency = 3,
  }) async {
    refreshCalls++;
    final book = books.first;
    resolvedSource = resolveSource(book);
    return const ShelfTocUpdateResult(
      requested: 1,
      eligible: 1,
      updated: 1,
      failed: 0,
      skipped: 0,
    );
  }

  @override
  Future<void> removeBook(String bookId) async {
    removedBookId = bookId;
    publish(
      BookshelfState.success(
        snapshot.books.where((book) => book.id != bookId).toList(),
      ),
    );
  }
}

final class _BookshelfStateNotifier extends BookshelfNotifier {
  _BookshelfStateNotifier(this.bookProvider) {
    bookProvider.onSnapshotChanged = _syncFromProvider;
  }

  final _BookshelfStateBookProvider bookProvider;
  int loadCalls = 0;

  @override
  BookshelfState build() => bookProvider.snapshot;

  void _syncFromProvider() => state = bookProvider.snapshot;

  @override
  Future<void> load() async {
    loadCalls++;
    await bookProvider.loadBooks();
    state = bookProvider.snapshot;
  }

  void publish(BookshelfState next) {
    bookProvider.publish(next);
    state = next;
  }
}

final class _FakeBookshelfDisplayPrefsPort
    implements BookshelfDisplayPrefsPort {
  const _FakeBookshelfDisplayPrefsPort();

  @override
  Future<BookshelfDisplayPrefs> load() async => const BookshelfDisplayPrefs();

  @override
  Future<bool> saveGrouped(bool value) async => true;

  @override
  Future<bool> savePinned(Iterable<String> ids) async => true;
}

final class _FakeBookGroupStore implements BookGroupStorePort {
  const _FakeBookGroupStore();

  @override
  List<BookGroup> get cached => const [];

  @override
  Future<void> syncNamesFromBooks(Iterable<String> names) async {}
}

final class _FakeBookshelfLocalBookPort implements BookshelfLocalBookPort {
  const _FakeBookshelfLocalBookPort();

  @override
  Future<Book?> importLocalBook() async => null;
}

final class _FakeBookRepository implements BookRepository {
  @override
  Future<void> insert(Book book) async {}

  @override
  Future<List<Book>> getAll() async => const [];

  @override
  Future<void> updateProgress(
    String bookId,
    double progress,
    String? chapter, {
    int pageIndex = 0,
  }) async {}

  @override
  Future<void> delete(String bookId) async {}

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
  Future<void> updateGroup(String bookId, String group) async {}

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

final class _FakeChapterContentCache implements ChapterContentCachePort {
  const _FakeChapterContentCache();

  @override
  Future<int> clearInvalid(Set<String> validBookIds) async => 0;

  @override
  Future<String?> get(String bookId, String chapterId) async => null;

  @override
  Future<void> save(String bookId, String chapterId, String content) async {}

  @override
  Future<void> delete(String bookId, String chapterId) async {}

  @override
  Future<void> clearAll() async {}

  @override
  Future<void> clearBook(String bookId) async {}

  @override
  Future<Set<String>> listChapterIds(String bookId) async => const {};

  @override
  String sanitizeChapterId(String chapterId) => chapterId;

  @override
  Future<bool> has(String bookId, String chapterId) async => false;

  @override
  Future<Map<String, int>> mapWordCounts(
    String bookId, {
    Set<String>? chapterIds,
  }) async => const {};

  @override
  Future<({int bytes, int chapterFiles})> stats(String bookId) async =>
      (bytes: 0, chapterFiles: 0);
}
