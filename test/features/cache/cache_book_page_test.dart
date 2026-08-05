import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/book/book_provider_source_port.dart';
import 'package:legado_flutter/application/cache/cache_book_download_port.dart';
import 'package:legado_flutter/application/cache/cache_book_shelf_port.dart';
import 'package:legado_flutter/application/preferences/download_choice_prefs_port.dart';
import 'package:legado_flutter/application/source_management/source_notifier.dart';
import 'package:legado_flutter/application/source_management/source_management_book_source_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/domain/ports/book_source_validation_port.dart';
import 'package:legado_flutter/domain/ports/chapter_content_cache_port.dart';
import 'package:legado_flutter/domain/repositories/book_repository.dart';
import 'package:legado_flutter/domain/repositories/book_source_repository.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/features/cache/cache_book_page.dart';
import 'package:legado_flutter/providers/book_provider.dart';
import 'package:legado_flutter/providers/source_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('缓存下载通过端口加载目录并下载章节', (tester) async {
    final source = const BookSource(
      bookSourceUrl: 'https://source.example',
      bookSourceName: '测试书源',
    );
    final book = Book(
      id: 'book-1',
      name: '测试书',
      author: '测试作者',
      sourceUrl: 'https://source.example/book/1',
      bookSourceUrl: source.bookSourceUrl,
    );
    final chapters = [
      Chapter(
        id: 'chapter-1',
        bookId: book.id,
        title: '第一章',
        index: 0,
        url: 'https://source.example/book/1/1',
      ),
    ];
    final cache = _FakeChapterContentCache();
    final downloadPort = _RecordingCacheBookDownloadPort(chapters: chapters);
    final sourceProvider = _LegacyLookupGuardSourceProvider(
      repository: _FakeBookSourceRepository([source]),
      validationPort: _FakeValidationPort(),
      sourceService: _FakeSourceManagementBookSourcePort(),
    );
    addTearDown(sourceProvider.dispose);
    await sourceProvider.loadSources();

    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          sourceControllerProvider.overrideWithValue(sourceProvider.controller),
        ],
        child: MultiProvider(
          providers: [
            Provider<DownloadChoicePrefsPort>.value(
              value: const _FakeDownloadChoicePrefsPort(),
            ),
          ],
          child: MaterialApp(
            home: CacheBookPage(
              contentCache: cache,
              shelfPort: _FakeCacheBookShelfPort(
                books: [book],
                chapters: chapters,
              ),
              downloadPort: downloadPort,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('下载'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '下载'));
    await tester.pumpAndSettle();

    expect(downloadPort.loadedSource, same(source));
    expect(downloadPort.downloadedSource, same(source));
    expect(downloadPort.downloadedBookId, book.id);
    expect(downloadPort.downloadedChapters, chapters);
    expect(downloadPort.downloadConcurrency, 1);
  });

  testWidgets('缓存下载进度和取消通过端口状态更新', (tester) async {
    final book = const Book(id: 'book-1', name: '测试书', author: '测试作者');
    final chapters = const [
      Chapter(
        id: 'chapter-1',
        bookId: 'book-1',
        title: '第一章',
        index: 0,
        url: 'https://source.example/book/1/1',
      ),
    ];
    final cache = _FakeChapterContentCache();
    final downloadPort = _RecordingCacheBookDownloadPort(
      chapters: chapters,
      initialState: const CacheBookDownloadState(
        isDownloading: true,
        downloadBookId: 'book-1',
        completed: 1,
        total: 4,
      ),
    );
    final sourceProvider = _LegacyLookupGuardSourceProvider(
      repository: _FakeBookSourceRepository([]),
      validationPort: _FakeValidationPort(),
      sourceService: _FakeSourceManagementBookSourcePort(),
    );
    addTearDown(sourceProvider.dispose);

    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          sourceControllerProvider.overrideWithValue(sourceProvider.controller),
        ],
        child: MultiProvider(
          providers: [
            Provider<DownloadChoicePrefsPort>.value(
              value: const _FakeDownloadChoicePrefsPort(),
            ),
          ],
          child: MaterialApp(
            home: CacheBookPage(
              contentCache: cache,
              shelfPort: _FakeCacheBookShelfPort(
                books: [book],
                chapters: chapters,
              ),
              downloadPort: downloadPort,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('缓存中 1/4'), findsOneWidget);
    final progress = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(progress.value, 0.25);

    await tester.tap(find.byTooltip('停止'));
    expect(downloadPort.cancelCalls, 1);
  });

  testWidgets('独立宿主通过显式 SourceController 查找书源', (tester) async {
    final source = const BookSource(
      bookSourceUrl: 'https://source.example',
      bookSourceName: '测试书源',
    );
    final book = Book(
      id: 'book-1',
      name: '测试书',
      author: '测试作者',
      sourceUrl: 'https://source.example/book/1',
      bookSourceUrl: source.bookSourceUrl,
    );
    final chapters = [
      Chapter(
        id: 'chapter-1',
        bookId: book.id,
        title: '第一章',
        index: 0,
        url: 'https://source.example/book/1/1',
      ),
    ];
    final cache = _FakeChapterContentCache();
    final bookProvider = _RecordingBookProvider(
      book: book,
      chapters: chapters,
      cache: cache,
    );
    final sourceProvider = _LegacyLookupGuardSourceProvider(
      repository: _FakeBookSourceRepository([source]),
      validationPort: _FakeValidationPort(),
      sourceService: _FakeSourceManagementBookSourcePort(),
    );
    addTearDown(sourceProvider.dispose);
    await sourceProvider.loadSources();

    await tester.pumpWidget(
      riverpod.ProviderScope(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<BookProvider>.value(value: bookProvider),
            Provider<DownloadChoicePrefsPort>.value(
              value: const _FakeDownloadChoicePrefsPort(),
            ),
          ],
          child: MaterialApp(
            home: CacheBookPage(
              contentCache: cache,
              sourceController: sourceProvider.controller,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('测试书'), findsOneWidget);
    await tester.tap(find.byTooltip('下载'));
    await tester.pumpAndSettle();
    expect(find.text('下载选项'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '下载'));
    await tester.pumpAndSettle();

    expect(bookProvider.loadedSource, same(source));
    expect(bookProvider.downloadedSource, same(source));
  });
}

final class _FakeCacheBookShelfPort implements CacheBookShelfPort {
  const _FakeCacheBookShelfPort({required this.books, required this.chapters});

  @override
  final List<Book> books;
  final List<Chapter> chapters;

  @override
  Future<int> getChapterCount(String bookId) async => chapters.length;

  @override
  Future<List<Chapter>> getLocalChapters(String bookId) async => chapters;
}

final class _RecordingCacheBookDownloadPort extends ChangeNotifier
    implements CacheBookDownloadPort {
  _RecordingCacheBookDownloadPort({
    required this.chapters,
    CacheBookDownloadState initialState = const CacheBookDownloadState(),
  }) : _state = initialState;

  final List<Chapter> chapters;
  final CacheBookDownloadState _state;
  BookSource? loadedSource;
  BookSource? downloadedSource;
  String? downloadedBookId;
  List<Chapter>? downloadedChapters;
  int? downloadConcurrency;
  int cancelCalls = 0;

  @override
  CacheBookDownloadState get state => _state;

  @override
  void cancelDownload() {
    cancelCalls++;
  }

  @override
  Future<List<Chapter>> loadChapters(
    Book book, {
    required BookSource source,
  }) async {
    loadedSource = source;
    return List<Chapter>.unmodifiable(chapters);
  }

  @override
  Future<void> downloadAllChapters(
    String bookId,
    List<Chapter> chapters,
    BookSource source, {
    int concurrency = 1,
  }) async {
    downloadedBookId = bookId;
    downloadedChapters = chapters;
    downloadedSource = source;
    downloadConcurrency = concurrency;
  }
}

final class _RecordingBookProvider extends BookProvider {
  _RecordingBookProvider({
    required this.book,
    required this.chapters,
    required ChapterContentCachePort cache,
  }) : super(
         repository: _FakeBookRepository(),
         sourceService: _FakeBookProviderSourcePort(),
         contentCache: cache,
       );

  final Book book;
  final List<Chapter> chapters;
  BookSource? loadedSource;
  BookSource? downloadedSource;

  @override
  List<Book> get books => [book];

  @override
  List<Chapter> get currentChapters => chapters;

  @override
  bool get isDownloading => false;

  @override
  int get downloadCompleted => 0;

  @override
  int get downloadTotal => 0;

  @override
  String get downloadBookId => '';

  @override
  double get downloadProgress => 0;

  @override
  Future<int> getChapterCount(String bookId) async => chapters.length;

  @override
  Future<void> loadChapters(
    Book book, {
    required BookSource source,
    bool forceRefresh = false,
    bool backgroundRefresh = false,
  }) async {
    loadedSource = source;
  }

  @override
  Future<void> downloadAllChapters(
    String bookId,
    List<Chapter> chapters,
    BookSource source, {
    int concurrency = 1,
  }) async {
    downloadedSource = source;
  }
}

final class _FakeBookSourceRepository implements BookSourceRepository {
  _FakeBookSourceRepository(Iterable<BookSource> initial)
    : sources = List<BookSource>.of(initial);

  final List<BookSource> sources;

  @override
  Future<List<BookSource>> getAll() async => List<BookSource>.of(sources);

  @override
  Future<List<BookSource>> getEnabled() async =>
      sources.where((source) => source.enabled).toList();

  @override
  Future<void> upsert(BookSource source) async {}

  @override
  Future<void> upsertAll(List<BookSource> sources) async {}

  @override
  Future<void> update(BookSource source) async {}

  @override
  Future<void> toggle(String url, bool enabled) async {}

  @override
  Future<void> delete(String url) async {}
}

final class _LegacyLookupGuardSourceProvider extends SourceProvider {
  _LegacyLookupGuardSourceProvider({
    required super.repository,
    required super.validationPort,
    required super.sourceService,
  });

  @override
  BookSource? findSourceForBook(Book book) => null;
}

final class _FakeValidationPort implements BookSourceValidationPort {
  @override
  bool get isAvailable => false;

  @override
  Future<BookSourceValidationSnapshot> validateSource(
    BookSource source, {
    required String keyword,
  }) {
    throw UnimplementedError();
  }
}

final class _FakeSourceManagementBookSourcePort
    implements SourceManagementBookSourcePort {
  @override
  Future<List<BookSource>> fetchSourcesFromUrl(String url) async => [];

  @override
  Future<List<Map<String, String>>> search(
    BookSource source,
    String keyword,
  ) async => [];

  @override
  List<Book> resultsToBooks(
    List<Map<String, String>> results,
    String sourceUrl,
  ) => [];
}

final class _FakeBookRepository implements BookRepository {
  @override
  Future<void> insert(Book book) async {}

  @override
  Future<List<Book>> getAll() async => [];

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
  Future<List<Chapter>> getChapters(String bookId) async => [];

  @override
  Future<String?> getChapterContent(String chapterId) async => null;

  @override
  Future<void> saveChapterContent(String chapterId, String content) async {}

  @override
  Future<void> clearChapterContent(Chapter chapter) async {}
}

final class _FakeBookProviderSourcePort implements BookProviderSourcePort {
  @override
  Future<Map<String, String>> getBookInfo(
    BookSource source,
    String bookUrl,
  ) async => {};

  @override
  Future<List<Map<String, String>>> search(
    BookSource source,
    String keyword,
  ) async => [];

  @override
  List<Book> resultsToBooks(
    List<Map<String, String>> results,
    String sourceUrl,
  ) => [];

  @override
  Future<List<Chapter>> getChapters(
    Book book, {
    required BookSource source,
  }) async => [];

  @override
  Future<String> getChapterContent(
    String url, {
    required BookSource source,
  }) async => '';

  @override
  Future<String> getChapterContentWithNextChapter(
    String url, {
    required BookSource source,
    String? nextChapterUrl,
  }) async => '';
}

final class _FakeChapterContentCache implements ChapterContentCachePort {
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
  Future<Set<String>> listChapterIds(String bookId) async => {};

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

final class _FakeDownloadChoicePrefsPort implements DownloadChoicePrefsPort {
  const _FakeDownloadChoicePrefsPort();

  @override
  Future<DownloadChoicePrefs> load() async =>
      const DownloadChoicePrefs(concurrency: 1, nextN: 50);

  @override
  Future<bool> save({required int concurrency, required int nextN}) async =>
      true;
}
