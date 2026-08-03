import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/book/book_provider_source_port.dart';
import 'package:legado_flutter/application/diagnostics/app_log_port.dart';
import 'package:legado_flutter/application/platform/clipboard_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/domain/diagnostics/diagnostic_record.dart';
import 'package:legado_flutter/domain/ports/chapter_content_cache_port.dart';
import 'package:legado_flutter/domain/repositories/book_repository.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/features/bookshelf/add_book_url_dialog.dart';
import 'package:legado_flutter/providers/book_provider.dart';
import 'package:legado_flutter/providers/source_provider.dart';
import 'package:provider/provider.dart';

import '../../application/source_management/source_controller_test.dart'
    as source_fixtures;

void main() {
  testWidgets('pastes text through the injected clipboard port', (
    tester,
  ) async {
    final clipboard = _FakeClipboard('https://example.com/book');
    final sourceProvider = await _createSourceProvider();

    await tester.pumpWidget(
      _withProviders(
        sourceProvider: sourceProvider,
        child: MaterialApp(home: AddBookUrlDialog(clipboard: clipboard)),
      ),
    );

    await tester.tap(find.text('粘贴'));
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(clipboard.pasteCalls, 1);
    expect(field.controller!.text, 'https://example.com/book');
  });

  testWidgets('imports URLs with sources from the shared SourceController', (
    tester,
  ) async {
    final source = BookSource(
      bookSourceUrl: 'https://source.example',
      bookSourceName: '共享书源',
    );
    final sourceProvider = await _createSourceProvider([source]);
    final bookProvider = _RecordingBookProvider();

    await tester.pumpWidget(
      _withProviders(
        sourceProvider: sourceProvider,
        bookProvider: bookProvider,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => AddBookUrlDialog.show(context),
                child: const Text('打开添加网址'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开添加网址'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'https://source.example/book/1',
    );
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(bookProvider.receivedText, 'https://source.example/book/1');
    expect(bookProvider.receivedSources, [source]);
  });
}

Future<SourceProvider> _createSourceProvider([
  Iterable<BookSource> sources = const [],
]) async {
  final repository = source_fixtures.createRepositoryForNotifierTest();
  await repository.upsertAll(sources.toList());
  final provider = SourceProvider(
    repository: repository,
    validationPort: source_fixtures.createValidationPortForNotifierTest(),
    sourceService: source_fixtures.createSourceServiceForNotifierTest(),
  );
  await provider.loadSources();
  return provider;
}

Widget _withProviders({
  required SourceProvider sourceProvider,
  BookProvider? bookProvider,
  required Widget child,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SourceProvider>.value(value: sourceProvider),
      if (bookProvider != null)
        ChangeNotifierProvider<BookProvider>.value(value: bookProvider),
      Provider<AppLogPort>.value(value: const _FakeAppLog()),
    ],
    child: child,
  );
}

class _FakeClipboard implements ClipboardPort {
  _FakeClipboard(this.pastedText);

  final String pastedText;
  var pasteCalls = 0;

  @override
  Future<void> copyText(String text) async {}

  @override
  Future<String?> pasteText() async {
    pasteCalls++;
    return pastedText;
  }
}

final class _FakeAppLog implements AppLogPort {
  const _FakeAppLog();

  @override
  List<DiagnosticRecord> get entries => const <DiagnosticRecord>[];

  @override
  Future<void> ensureLoaded() async {}

  @override
  Future<void> i(
    String message, {
    String category = 'app',
    String? source,
    Map<String, String> metadata = const {},
  }) async {}

  @override
  Future<void> w(
    String message, {
    String category = 'app',
    String? source,
    Map<String, String> metadata = const {},
  }) async {}

  @override
  Future<void> e(
    String message, {
    String category = 'app',
    String? source,
    Map<String, String> metadata = const {},
  }) async {}

  @override
  Future<void> clear() async {}

  @override
  String exportText() => '';
}

final class _RecordingBookProvider extends BookProvider {
  _RecordingBookProvider()
    : super(
        repository: _MemoryBookRepository(),
        sourceService: const _NoopBookSourcePort(),
        contentCache: const _NoopChapterCache(),
      );

  String? receivedText;
  List<BookSource>? receivedSources;

  @override
  Future<({int success, int fail})> addBooksByUrls(
    String rawText, {
    required List<BookSource> sources,
    void Function(int index, int total, String url)? onProgress,
  }) async {
    receivedText = rawText;
    receivedSources = List<BookSource>.of(sources);
    onProgress?.call(1, 1, rawText);
    return (success: 1, fail: 0);
  }
}

final class _NoopBookSourcePort implements BookProviderSourcePort {
  const _NoopBookSourcePort();

  @override
  Future<Map<String, String>> getBookInfo(
    BookSource source,
    String bookUrl,
  ) async => {};

  @override
  Future<List<Map<String, String>>> search(
    BookSource source,
    String keyword,
  ) async => const [];

  @override
  List<Book> resultsToBooks(
    List<Map<String, String>> results,
    String sourceUrl,
  ) => const [];

  @override
  Future<List<Chapter>> getChapters(
    Book book, {
    required BookSource source,
  }) async => const [];

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

final class _MemoryBookRepository implements BookRepository {
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
