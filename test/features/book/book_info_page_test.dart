import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/source_management/source_notifier.dart';
import 'package:legado_flutter/application/book/book_read_status_port.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_membership_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/domain/ports/book_source_book_info_port.dart';
import 'package:legado_flutter/domain/ports/book_source_content_port.dart';
import 'package:legado_flutter/domain/ports/book_source_explore_port.dart';
import 'package:legado_flutter/domain/ports/book_source_search_port.dart';
import 'package:legado_flutter/domain/ports/book_source_toc_port.dart';
import 'package:legado_flutter/domain/ports/chapter_content_cache_port.dart';
import 'package:legado_flutter/domain/ports/public_text_fetch_port.dart';
import 'package:legado_flutter/domain/repositories/book_repository.dart';
import 'package:legado_flutter/domain/repositories/book_source_repository.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/features/book/book_info_page.dart';
import 'package:legado_flutter/providers/book_provider.dart';
import 'package:legado_flutter/providers/source_provider.dart';
import 'package:legado_flutter/services/book_source_service.dart';
import 'package:provider/provider.dart';

import '../../application/source_management/source_controller_test.dart'
    as source_fixtures;

void main() {
  testWidgets('详情页阅读状态通过应用端口写入', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    final readStatusPort = _RecordingBookReadStatusPort();
    try {
      await _pumpEditPage(
        tester,
        inShelf: true,
        readStatusPort: readStatusPort,
      );

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('阅读状态'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2刷完'));
      await tester.pumpAndSettle();

      expect(readStatusPort.calls, [('book-1', 3)]);
    } finally {
      await tester.binding.setSurfaceSize(null);
    }
  });

  testWidgets('详情页设置分组从书架成员端口读取分组列表', (tester) async {
    final source = BookSource(
      bookSourceUrl: 'https://source.example',
      bookSourceName: '分组书源',
    );
    final sourceService = _createSourceService();
    final sourceProvider = SourceProvider(
      repository: _MemorySourceRepository([source]),
      validationPort: source_fixtures.createValidationPortForNotifierTest(),
      sourceService: sourceService,
    );
    await sourceProvider.loadSources();

    const book = Book(
      id: 'book-1',
      name: '测试书',
      author: '作者',
      sourceUrl: 'https://source.example/book',
      bookSourceUrl: 'https://source.example',
    );
    const groupedBook = Book(id: 'book-2', name: '另一本书', group: '来自端口');
    final bookProvider = BookProvider(
      repository: _MemoryBookRepository(),
      sourceService: sourceService,
      contentCache: const _NoopChapterCache(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SourceProvider>.value(value: sourceProvider),
          ChangeNotifierProvider<BookProvider>.value(value: bookProvider),
          ListenableProvider<BookshelfMembershipPort>.value(
            value: _StaticBookshelfMembershipPort([book, groupedBook]),
          ),
          Provider<BookSourceSearchPort>.value(value: const _EmptySearchPort()),
        ],
        child: riverpod.ProviderScope(
          overrides: [
            sourceControllerProvider.overrideWithValue(
              sourceProvider.controller,
            ),
          ],
          child: const MaterialApp(home: BookInfoPage(book: book)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('设置分组'));
    await tester.pumpAndSettle();

    expect(find.text('来自端口'), findsOneWidget);
  });

  testWidgets('详情页从共享 SourceController 读取书源名称', (tester) async {
    final source = BookSource(
      bookSourceUrl: 'https://source.example',
      bookSourceName: '共享书源',
    );
    final sourceRepository = _MemorySourceRepository([source]);
    final sourceService = _createSourceService();
    final sourceProvider = SourceProvider(
      repository: sourceRepository,
      validationPort: source_fixtures.createValidationPortForNotifierTest(),
      sourceService: sourceService,
    );
    await sourceProvider.loadSources();

    final bookProvider = BookProvider(
      repository: _MemoryBookRepository(),
      sourceService: sourceService,
      contentCache: const _NoopChapterCache(),
    );
    final book = Book(
      id: 'book-1',
      name: '测试书',
      author: '作者',
      sourceUrl: 'https://source.example/book',
      bookSourceUrl: source.bookSourceUrl,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SourceProvider>.value(value: sourceProvider),
          ChangeNotifierProvider<BookProvider>.value(value: bookProvider),
          ListenableProvider<BookshelfMembershipPort>.value(
            value: _TestBookshelfMembershipPort(bookProvider),
          ),
          Provider<BookSourceSearchPort>.value(value: const _EmptySearchPort()),
        ],
        child: riverpod.ProviderScope(
          overrides: [
            sourceControllerProvider.overrideWithValue(
              sourceProvider.controller,
            ),
          ],
          child: MaterialApp(home: BookInfoPage(book: book)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('共享书源'), findsOneWidget);
  });

  testWidgets('书架内自动补全封面后同步 Provider 快照', (tester) async {
    final fixture = await _pumpCoverPage(tester, inShelf: true);

    expect(fixture.repository.coverUpdates, [
      ('book-1', 'https://cover.example/new.jpg'),
    ]);
    expect(
      fixture.provider.books.single.coverUrl,
      'https://cover.example/new.jpg',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('非书架书籍自动补全封面不落库', (tester) async {
    final fixture = await _pumpCoverPage(tester, inShelf: false);

    expect(fixture.repository.coverUpdates, isEmpty);
    expect(fixture.provider.books, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('封面写入失败保持原有静默降级且不修改 Provider 快照', (tester) async {
    final fixture = await _pumpCoverPage(
      tester,
      inShelf: true,
      failCoverWrite: true,
    );

    expect(fixture.repository.coverUpdates, [
      ('book-1', 'https://cover.example/new.jpg'),
    ]);
    expect(fixture.provider.books.single.coverUrl, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('书架内编辑基础信息走 Provider 字段级写入', (tester) async {
    final fixture = await _pumpEditPage(tester, inShelf: true);

    await _editBookInfo(
      tester,
      name: ' 新书名 ',
      author: ' 新作者 ',
      description: ' 新简介 ',
    );

    expect(fixture.repository.detailsUpdates, [
      ('book-1', '新书名', '新作者', '新简介'),
    ]);
    final updated = fixture.provider.books.single;
    expect(updated.name, '新书名');
    expect(updated.author, '新作者');
    expect(updated.description, '新简介');
    expect(updated.currentPageIndex, 65537);
    expect(updated.coverUrl, 'https://cover.example/current.jpg');
    expect(updated.sourceUrl, 'https://source.example/book');
  });

  testWidgets('非书架书籍编辑基础信息只更新页面且不落库', (tester) async {
    final fixture = await _pumpEditPage(tester, inShelf: false);

    await _editBookInfo(
      tester,
      name: ' 新书名 ',
      author: ' 新作者 ',
      description: ' 新简介 ',
    );

    expect(fixture.repository.detailsUpdates, isEmpty);
    expect(fixture.provider.books, isEmpty);
    expect(find.text('新书名'), findsOneWidget);
  });
}

Future<void> _editBookInfo(
  WidgetTester tester, {
  required String name,
  required String author,
  required String description,
}) async {
  await tester.tap(find.byType(PopupMenuButton<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('编辑'));
  await tester.pumpAndSettle();

  final fields = find.byType(TextFormField);
  expect(fields, findsNWidgets(3));
  await tester.enterText(fields.at(0), name);
  await tester.enterText(fields.at(1), author);
  await tester.enterText(fields.at(2), description);
  await tester.tap(find.widgetWithText(FilledButton, '保存'));
  await tester.pumpAndSettle();
}

Future<({BookProvider provider, _MemoryBookRepository repository})>
_pumpEditPage(
  WidgetTester tester, {
  required bool inShelf,
  BookReadStatusPort? readStatusPort,
}) async {
  final source = BookSource(
    bookSourceUrl: 'https://source.example',
    bookSourceName: '编辑书源',
  );
  final sourceRepository = _MemorySourceRepository([source]);
  final sourceService = _createSourceService();
  final sourceProvider = SourceProvider(
    repository: sourceRepository,
    validationPort: source_fixtures.createValidationPortForNotifierTest(),
    sourceService: sourceService,
  );
  await sourceProvider.loadSources();

  final repository = _MemoryBookRepository();
  final book = Book(
    id: 'book-1',
    name: '旧书名',
    author: '旧作者',
    coverUrl: 'https://cover.example/current.jpg',
    description: '旧简介',
    sourceUrl: 'https://source.example/book',
    bookSourceUrl: source.bookSourceUrl,
    currentPageIndex: 65537,
  );
  if (inShelf) await repository.insert(book);
  final bookProvider = BookProvider(
    repository: repository,
    sourceService: sourceService,
    contentCache: const _NoopChapterCache(),
  );
  await bookProvider.loadBooks(runMaintenance: false);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SourceProvider>.value(value: sourceProvider),
        ChangeNotifierProvider<BookProvider>.value(value: bookProvider),
        ListenableProvider<BookshelfMembershipPort>.value(
          value: _TestBookshelfMembershipPort(bookProvider),
        ),
        Provider<BookSourceSearchPort>.value(value: const _EmptySearchPort()),
      ],
      child: riverpod.ProviderScope(
        overrides: [
          sourceControllerProvider.overrideWithValue(sourceProvider.controller),
        ],
        child: MaterialApp(
          home: BookInfoPage(book: book, readStatusPort: readStatusPort),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (provider: bookProvider, repository: repository);
}

Future<({BookProvider provider, _MemoryBookRepository repository})>
_pumpCoverPage(
  WidgetTester tester, {
  required bool inShelf,
  bool failCoverWrite = false,
}) async {
  final source = BookSource(
    bookSourceUrl: 'https://source.example',
    bookSourceName: '封面书源',
  );
  final sourceRepository = _MemorySourceRepository([source]);
  final sourceService = _createSourceService();
  final sourceProvider = SourceProvider(
    repository: sourceRepository,
    validationPort: source_fixtures.createValidationPortForNotifierTest(),
    sourceService: sourceService,
  );
  await sourceProvider.loadSources();

  final repository = _MemoryBookRepository()..failCoverWrite = failCoverWrite;
  final book = Book(
    id: 'book-1',
    name: '测试书',
    author: '作者',
    sourceUrl: 'https://source.example/book',
    bookSourceUrl: source.bookSourceUrl,
    currentPageIndex: 65537,
  );
  if (inShelf) await repository.insert(book);
  final bookProvider = BookProvider(
    repository: repository,
    sourceService: sourceService,
    contentCache: const _NoopChapterCache(),
  );
  await bookProvider.loadBooks(runMaintenance: false);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SourceProvider>.value(value: sourceProvider),
        ChangeNotifierProvider<BookProvider>.value(value: bookProvider),
        ListenableProvider<BookshelfMembershipPort>.value(
          value: _TestBookshelfMembershipPort(bookProvider),
        ),
        Provider<BookSourceSearchPort>.value(value: const _CoverSearchPort()),
      ],
      child: riverpod.ProviderScope(
        overrides: [
          sourceControllerProvider.overrideWithValue(sourceProvider.controller),
        ],
        child: MaterialApp(home: BookInfoPage(book: book)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (provider: bookProvider, repository: repository);
}

BookSourceService _createSourceService() {
  return BookSourceService(
    searchPort: const _EmptySearchPort(),
    bookInfoPort: const _EmptyBookInfoPort(),
    contentPort: const _EmptyContentPort(),
    explorePort: const _EmptyExplorePort(),
    tocPort: const _EmptyTocPort(),
    publicTextPort: const _EmptyPublicTextPort(),
  );
}

final class _MemorySourceRepository implements BookSourceRepository {
  _MemorySourceRepository(Iterable<BookSource> initial)
    : sources = List<BookSource>.of(initial);

  final List<BookSource> sources;

  @override
  Future<void> upsert(BookSource source) async {
    await update(source);
  }

  @override
  Future<void> upsertAll(List<BookSource> values) async {
    for (final value in values) {
      await update(value);
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
  final chapters = <String, List<Chapter>>{};
  final coverUpdates = <(String, String)>[];
  final detailsUpdates = <(String, String, String, String)>[];
  bool failCoverWrite = false;

  @override
  Future<void> insert(Book book) async => books[book.id] = book;

  @override
  Future<List<Book>> getAll() async => books.values.toList();

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
  Future<void> updateCover(String bookId, String coverUrl) async {
    coverUpdates.add((bookId, coverUrl));
    if (failCoverWrite) throw StateError('封面写入失败');
    final book = books[bookId];
    if (book != null) books[bookId] = book.copyWith(coverUrl: coverUrl);
  }

  @override
  Future<void> updateBookDetails(
    String bookId,
    String name,
    String author,
    String description,
  ) async {
    detailsUpdates.add((bookId, name, author, description));
    final book = books[bookId];
    if (book != null) {
      books[bookId] = book.copyWith(
        name: name,
        author: author,
        description: description,
      );
    }
  }

  @override
  Future<void> updateGroup(String bookId, String group) async {}

  @override
  Future<void> insertChapters(List<Chapter> values) async {
    if (values.isNotEmpty) chapters[values.first.bookId] = List.of(values);
  }

  @override
  Future<List<Chapter>> getChapters(String bookId) async =>
      List.of(chapters[bookId] ?? const []);

  @override
  Future<String?> getChapterContent(String chapterId) async => null;

  @override
  Future<void> saveChapterContent(String chapterId, String content) async {}

  @override
  Future<void> clearChapterContent(Chapter chapter) async {}
}

final class _TestBookshelfMembershipPort extends ChangeNotifier
    implements BookshelfMembershipPort {
  _TestBookshelfMembershipPort(this._provider);

  final BookProvider _provider;

  @override
  List<Book> get books => _provider.books;
}

final class _RecordingBookReadStatusPort implements BookReadStatusPort {
  final calls = <(String, int)>[];

  @override
  Future<void> updateReadIteration(Book book, int readIteration) async {
    calls.add((book.id, readIteration));
  }
}

final class _StaticBookshelfMembershipPort extends ChangeNotifier
    implements BookshelfMembershipPort {
  _StaticBookshelfMembershipPort(Iterable<Book> books)
    : _books = List<Book>.unmodifiable(books);

  final List<Book> _books;

  @override
  List<Book> get books => _books;
}

final class _NoopChapterCache implements ChapterContentCachePort {
  const _NoopChapterCache();

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
  Future<int> clearInvalid(Set<String> validBookIds) async => 0;

  @override
  Future<bool> has(String bookId, String chapterId) async => false;

  @override
  Future<Set<String>> listChapterIds(String bookId) async => <String>{};

  @override
  String sanitizeChapterId(String chapterId) => chapterId;

  @override
  Future<Map<String, int>> mapWordCounts(
    String bookId, {
    Set<String>? chapterIds,
  }) async => {};

  @override
  Future<({int bytes, int chapterFiles})> stats(String bookId) async =>
      (bytes: 0, chapterFiles: 0);
}

final class _EmptySearchPort implements BookSourceSearchPort {
  const _EmptySearchPort();

  @override
  Future<List<Map<String, String>>> search(
    BookSource source,
    String keyword,
  ) async => const [];
}

final class _CoverSearchPort implements BookSourceSearchPort {
  const _CoverSearchPort();

  @override
  Future<List<Map<String, String>>> search(
    BookSource source,
    String keyword,
  ) async => const [
    {'name': '测试书', 'coverUrl': 'https://cover.example/new.jpg'},
  ];
}

final class _EmptyBookInfoPort implements BookSourceBookInfoPort {
  const _EmptyBookInfoPort();

  @override
  Future<Map<String, String>> getBookInfo(
    BookSource source,
    String bookUrl,
  ) async => {};
}

final class _EmptyContentPort implements BookSourceContentPort {
  const _EmptyContentPort();

  @override
  Future<String> getContent(BookSource source, String chapterUrl) async => '';
}

final class _EmptyExplorePort implements BookSourceExplorePort {
  const _EmptyExplorePort();

  @override
  Future<List<Map<String, String>>> explore(
    BookSource source,
    String exploreUrl, {
    int page = 1,
  }) async => const [];
}

final class _EmptyTocPort implements BookSourceTocPort {
  const _EmptyTocPort();

  @override
  Future<List<Chapter>> getToc(BookSource source, Book book) async => const [];
}

final class _EmptyPublicTextPort implements PublicTextFetchPort {
  const _EmptyPublicTextPort();

  @override
  Future<String> fetch(String url, {String userAgent = ''}) async => '';
}
