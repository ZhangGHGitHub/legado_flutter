import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/book/book_info_chapter_port.dart';
import 'package:legado_flutter/application/book/book_metadata_port.dart';
import 'package:legado_flutter/application/source_management/source_notifier.dart';
import 'package:legado_flutter/application/book/book_read_status_port.dart';
import 'package:legado_flutter/application/cache/cache_book_download_port.dart';
import 'package:legado_flutter/application/reader/reader_source_access_port.dart';
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
  test('详情页宿主可以显式注入缓存下载端口', () {
    final cachePort = CacheBookDownloadPortCallbacks(
      changes: ChangeNotifier(),
      state: () => const CacheBookDownloadState(),
      loadChapters: (book, {required source}) async => const [],
      downloadAllChapters:
          (bookId, chapters, source, {concurrency = 1}) async {},
      cancelDownload: () {},
    );
    final page = BookInfoPage(
      book: const Book(id: 'book-1', name: '测试书'),
      cacheDownloadPort: cachePort,
    );

    expect(page.cacheDownloadPort, same(cachePort));
  });

  test('详情页宿主可以显式注入书源访问端口', () {
    final sourcePort = ReaderSourceAccessPortCallbacks(
      sourceForBook: (_) => null,
      availableSources: () => const [],
      autoChangeSource: (book, {required sources, concurrency = 4}) async =>
          null,
    );
    final page = BookInfoPage(
      book: const Book(id: 'book-1', name: '测试书'),
      sourceAccessPort: sourcePort,
    );

    expect(page.sourceAccessPort, same(sourcePort));
  });

  testWidgets('详情页显式书源访问端口优先于共享端口', (tester) async {
    final source = BookSource(
      bookSourceUrl: 'https://explicit.example',
      bookSourceName: '显式书源',
    );
    final explicitPort = ReaderSourceAccessPortCallbacks(
      sourceForBook: (_) => source,
      availableSources: () => [source],
      autoChangeSource: (book, {required sources, concurrency = 4}) async =>
          null,
    );
    final chapterPort = _RecordingBookInfoChapterPort();

    await _pumpEditPage(
      tester,
      inShelf: false,
      chapterPort: chapterPort,
      sourceAccessPort: explicitPort,
      providerSourceAccessPort: const EmptyReaderSourceAccessPort(),
    );

    expect(chapterPort.calls, [false]);
  });

  testWidgets('详情页缺少书源访问端口时使用明确空实现', (tester) async {
    final chapterPort = _RecordingBookInfoChapterPort();

    await _pumpEditPage(
      tester,
      inShelf: false,
      chapterPort: chapterPort,
      includeProviderSourceAccessPort: false,
    );

    expect(chapterPort.calls, isEmpty);
    expect(find.textContaining('编辑书源'), findsNothing);
  });

  testWidgets('详情页显式元数据端口优先于组合根端口', (tester) async {
    final widgetPort = _RecordingBookMetadataPort();
    final sharedPort = _RecordingBookMetadataPort();

    await _pumpEditPage(
      tester,
      inShelf: true,
      metadataPort: widgetPort,
      providerMetadataPort: sharedPort,
    );

    await _editBookInfo(
      tester,
      name: ' 新书名 ',
      author: ' 新作者 ',
      description: ' 新简介 ',
    );

    expect(widgetPort.detailsCalls, [('book-1', ' 新书名 ', ' 新作者 ', ' 新简介 ')]);
    expect(sharedPort.detailsCalls, isEmpty);
  });

  testWidgets('详情页显式章节端口优先并保留初次加载和强制刷新参数', (tester) async {
    final chapterPort = _RecordingBookInfoChapterPort();
    final providerPort = _RecordingBookInfoChapterPort();

    await _pumpEditPage(
      tester,
      inShelf: false,
      chapterPort: chapterPort,
      providerChapterPort: providerPort,
    );

    expect(chapterPort.calls, [false]);
    expect(providerPort.calls, isEmpty);
    expect(chapterPort.currentChapters.single.title, '第一章');

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('刷新目录'));
    await tester.pumpAndSettle();

    expect(chapterPort.calls, [false, true]);
    expect(providerPort.calls, isEmpty);
  });

  testWidgets('详情页未显式注入时复用共享章节端口', (tester) async {
    final providerPort = _RecordingBookInfoChapterPort();

    await _pumpEditPage(
      tester,
      inShelf: false,
      providerChapterPort: providerPort,
    );

    expect(providerPort.calls, [false]);
    expect(providerPort.currentChapters.single.title, '第一章');
    expect(tester.takeException(), isNull);
  });

  testWidgets('详情页章节端口异常仍被捕获且保留刷新调用', (tester) async {
    final chapterPort = _RecordingBookInfoChapterPort(failure: '目录端口失败');

    await _pumpEditPage(tester, inShelf: false, chapterPort: chapterPort);

    expect(chapterPort.calls, [false]);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('刷新目录'));
    await tester.pumpAndSettle();

    expect(chapterPort.calls, [false, true]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('详情页显式缓存端口优先并保留过滤、并发和同书取消', (tester) async {
    final chapterPort = _RecordingBookInfoChapterPort(
      loadedChapters: const [
        Chapter(
          id: 'chapter-downloaded',
          bookId: 'book-1',
          title: '已缓存',
          index: 0,
          url: 'https://source.example/downloaded',
          isDownloaded: true,
        ),
        Chapter(
          id: 'chapter-pending',
          bookId: 'book-1',
          title: '待缓存',
          index: 1,
          url: 'https://source.example/pending',
        ),
      ],
    );
    final widgetCachePort = _RecordingCacheBookDownloadPort();
    final sharedCachePort = _RecordingCacheBookDownloadPort();

    await _pumpEditPage(
      tester,
      inShelf: false,
      chapterPort: chapterPort,
      cacheDownloadPort: widgetCachePort,
      providerCacheDownloadPort: sharedCachePort,
    );

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('缓存全部'));
    await tester.pumpAndSettle();

    expect(widgetCachePort.downloadCalls, hasLength(1));
    expect(widgetCachePort.downloadCalls.single.bookId, 'book-1');
    expect(widgetCachePort.downloadCalls.single.chapters, hasLength(1));
    expect(
      widgetCachePort.downloadCalls.single.chapters.single.id,
      'chapter-pending',
    );
    expect(widgetCachePort.downloadCalls.single.concurrency, 1);
    expect(sharedCachePort.downloadCalls, isEmpty);

    widgetCachePort.downloadState = const CacheBookDownloadState(
      isDownloading: true,
      downloadBookId: 'book-1',
      completed: 1,
      total: 1,
    );
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('缓存全部'));
    await tester.pumpAndSettle();

    expect(widgetCachePort.cancelCalls, 1);
  });

  testWidgets('详情页未显式注入时复用共享缓存下载端口', (tester) async {
    final cachePort = _RecordingCacheBookDownloadPort();

    await _pumpEditPage(
      tester,
      inShelf: false,
      chapterPort: _RecordingBookInfoChapterPort(),
      providerCacheDownloadPort: cachePort,
    );

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('缓存全部'));
    await tester.pumpAndSettle();

    expect(cachePort.downloadCalls, hasLength(1));
  });

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

  testWidgets('详情页未显式注入时复用共享阅读状态端口', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    final readStatusPort = _RecordingBookReadStatusPort();
    try {
      await _pumpEditPage(
        tester,
        inShelf: true,
        providerReadStatusPort: readStatusPort,
      );

      await _selectReadIteration(tester, '2刷完');

      expect(readStatusPort.calls, [('book-1', 3)]);
    } finally {
      await tester.binding.setSurfaceSize(null);
    }
  });

  testWidgets('详情页缺少阅读状态端口时不回落到旧 Provider 写入', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    try {
      final fixture = await _pumpEditPage(tester, inShelf: true);

      await _selectReadIteration(tester, '2刷完');

      expect(fixture.repository.books.values.single.readIteration, 0);
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
          Provider<ReaderSourceAccessPort>.value(
            value: _readerSourceAccessPortFor(sourceProvider, bookProvider),
          ),
          ListenableProvider<BookshelfMembershipPort>.value(
            value: _StaticBookshelfMembershipPort([book, groupedBook]),
          ),
          Provider<BookMetadataPort>.value(
            value: const EmptyBookMetadataPort(),
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
          Provider<ReaderSourceAccessPort>.value(
            value: _readerSourceAccessPortFor(sourceProvider, bookProvider),
          ),
          ListenableProvider<BookshelfMembershipPort>.value(
            value: _TestBookshelfMembershipPort(bookProvider),
          ),
          Provider<BookMetadataPort>.value(
            value: const EmptyBookMetadataPort(),
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

  testWidgets('书架内编辑基础信息走元数据端口字段级写入', (tester) async {
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

Future<void> _selectReadIteration(WidgetTester tester, String label) async {
  await tester.tap(find.byType(PopupMenuButton<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('阅读状态'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Future<({BookProvider provider, _MemoryBookRepository repository})>
_pumpEditPage(
  WidgetTester tester, {
  required bool inShelf,
  BookReadStatusPort? readStatusPort,
  BookReadStatusPort? providerReadStatusPort,
  BookInfoChapterPort? chapterPort,
  BookInfoChapterPort? providerChapterPort,
  BookMetadataPort? metadataPort,
  BookMetadataPort? providerMetadataPort,
  CacheBookDownloadPort? cacheDownloadPort,
  CacheBookDownloadPort? providerCacheDownloadPort,
  ReaderSourceAccessPort? sourceAccessPort,
  ReaderSourceAccessPort? providerSourceAccessPort,
  bool includeProviderSourceAccessPort = true,
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
  final sharedMetadataPort =
      providerMetadataPort ??
      BookMetadataPortCallbacks(
        updateCover: bookProvider.updateBookCover,
        updateBookDetails: bookProvider.updateBookDetails,
      );

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SourceProvider>.value(value: sourceProvider),
        ChangeNotifierProvider<BookProvider>.value(value: bookProvider),
        if (includeProviderSourceAccessPort)
          Provider<ReaderSourceAccessPort>.value(
            value:
                providerSourceAccessPort ??
                _readerSourceAccessPortFor(sourceProvider, bookProvider),
          ),
        ListenableProvider<BookshelfMembershipPort>.value(
          value: _TestBookshelfMembershipPort(bookProvider),
        ),
        Provider<BookMetadataPort>.value(value: sharedMetadataPort),
        Provider<BookSourceSearchPort>.value(value: const _EmptySearchPort()),
        if (providerReadStatusPort != null)
          Provider<BookReadStatusPort>.value(value: providerReadStatusPort),
        if (providerChapterPort != null)
          Provider<BookInfoChapterPort>.value(value: providerChapterPort),
        if (providerCacheDownloadPort != null)
          ListenableProvider<CacheBookDownloadPort>.value(
            value: providerCacheDownloadPort,
          ),
      ],
      child: riverpod.ProviderScope(
        overrides: [
          sourceControllerProvider.overrideWithValue(sourceProvider.controller),
        ],
        child: MaterialApp(
          home: BookInfoPage(
            book: book,
            readStatusPort: readStatusPort,
            chapterPort: chapterPort,
            metadataPort: metadataPort,
            cacheDownloadPort: cacheDownloadPort,
            sourceAccessPort: sourceAccessPort,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (provider: bookProvider, repository: repository);
}

ReaderSourceAccessPort _readerSourceAccessPortFor(
  SourceProvider sourceProvider,
  BookProvider bookProvider,
) => ReaderSourceAccessPortCallbacks(
  sourceForBook: sourceProvider.findSourceForBook,
  availableSources: () => sourceProvider.sources,
  autoChangeSource: bookProvider.autoChangeSource,
);

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
  final metadataPort = BookMetadataPortCallbacks(
    updateCover: bookProvider.updateBookCover,
    updateBookDetails: bookProvider.updateBookDetails,
  );

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SourceProvider>.value(value: sourceProvider),
        ChangeNotifierProvider<BookProvider>.value(value: bookProvider),
        Provider<ReaderSourceAccessPort>.value(
          value: _readerSourceAccessPortFor(sourceProvider, bookProvider),
        ),
        ListenableProvider<BookshelfMembershipPort>.value(
          value: _TestBookshelfMembershipPort(bookProvider),
        ),
        Provider<BookMetadataPort>.value(value: metadataPort),
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

final class _RecordingBookMetadataPort implements BookMetadataPort {
  final coverCalls = <(String, String)>[];
  final detailsCalls = <(String, String, String, String)>[];

  @override
  Future<Book> updateCover(Book book, String coverUrl) async {
    coverCalls.add((book.id, coverUrl));
    return book.copyWith(coverUrl: coverUrl);
  }

  @override
  Future<Book?> updateBookDetails(
    String bookId, {
    required String name,
    required String author,
    required String description,
  }) async {
    detailsCalls.add((bookId, name, author, description));
    return null;
  }
}

final class _RecordingBookInfoChapterPort implements BookInfoChapterPort {
  _RecordingBookInfoChapterPort({
    this.failure,
    Iterable<Chapter>? loadedChapters,
  }) : _loadedChapters = loadedChapters?.toList();

  final String? failure;
  final List<Chapter>? _loadedChapters;
  final calls = <bool>[];
  final chapters = <Chapter>[];

  @override
  List<Chapter> get currentChapters => chapters;

  @override
  bool get isLoading => false;

  @override
  bool get isRefreshingToc => false;

  @override
  Future<void> loadChapters(
    Book book, {
    required BookSource source,
    bool forceRefresh = false,
  }) async {
    calls.add(forceRefresh);
    if (failure != null) throw StateError(failure!);
    chapters
      ..clear()
      ..addAll(
        _loadedChapters ??
            const [
              Chapter(
                id: 'chapter-1',
                bookId: 'book-1',
                title: '第一章',
                index: 0,
                url: 'https://source.example/chapter-1',
              ),
            ],
      );
  }
}

final class _RecordingCacheBookDownloadPort extends ChangeNotifier
    implements CacheBookDownloadPort {
  CacheBookDownloadState downloadState = const CacheBookDownloadState();
  final downloadCalls =
      <
        ({
          String bookId,
          List<Chapter> chapters,
          BookSource source,
          int concurrency,
        })
      >[];
  int cancelCalls = 0;

  @override
  CacheBookDownloadState get state => downloadState;

  @override
  Future<List<Chapter>> loadChapters(
    Book book, {
    required BookSource source,
  }) async => const [];

  @override
  Future<void> downloadAllChapters(
    String bookId,
    List<Chapter> chapters,
    BookSource source, {
    int concurrency = 1,
  }) async {
    downloadCalls.add((
      bookId: bookId,
      chapters: List<Chapter>.unmodifiable(chapters),
      source: source,
      concurrency: concurrency,
    ));
  }

  @override
  void cancelDownload() => cancelCalls++;
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
