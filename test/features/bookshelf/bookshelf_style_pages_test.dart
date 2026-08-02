import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/bookshelf/book_group_store_port.dart';
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
import 'package:legado_flutter/providers/book_provider.dart';
import 'package:legado_flutter/providers/source_provider.dart';
import 'package:provider/provider.dart';

import '../../application/source_management/source_controller_test.dart'
    as source_fixtures;
import '../../helpers/book_source_service_test_factory.dart';

void main() {
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
  required Widget child,
}) {
  return MaterialApp(
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<SourceProvider>.value(value: sourceProvider),
        ChangeNotifierProvider<BookProvider>.value(value: bookProvider),
        Provider<BookshelfDisplayPrefsPort>.value(
          value: const _FakeBookshelfDisplayPrefsPort(),
        ),
        Provider<BookGroupStorePort>.value(value: const _FakeBookGroupStore()),
        Provider<BookshelfLocalBookPort>.value(
          value: const _FakeBookshelfLocalBookPort(),
        ),
      ],
      child: child,
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
