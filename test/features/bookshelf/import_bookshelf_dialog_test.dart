import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:legado_flutter/application/book/book_provider_source_port.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_list_port.dart';
import 'package:legado_flutter/application/diagnostics/app_log_port.dart';
import 'package:legado_flutter/application/platform/clipboard_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/domain/diagnostics/diagnostic_record.dart';
import 'package:legado_flutter/domain/ports/chapter_content_cache_port.dart';
import 'package:legado_flutter/domain/ports/public_text_fetch_port.dart';
import 'package:legado_flutter/domain/repositories/book_repository.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/features/bookshelf/import_bookshelf_dialog.dart';
import 'package:legado_flutter/providers/book_provider.dart';
import 'package:legado_flutter/providers/source_provider.dart';

import '../../application/source_management/source_controller_test.dart'
    as source_fixtures;

class _FakeClipboardPort implements ClipboardPort {
  _FakeClipboardPort(this.value);

  final String? value;

  @override
  Future<void> copyText(String text) async {}

  @override
  Future<String?> pasteText() async => value;
}

final class _FakeBookshelfListPort implements BookshelfListPort {
  @override
  Future<String?> exportBooks(List<Book> books) async => null;

  @override
  Future<String?> pickFileText() async => null;

  @override
  Future<String> resolveInput(
    String input, {
    required PublicTextFetchPort fetchPort,
  }) async => input;

  @override
  List<BookshelfListEntry> parseEntries(String text) => [
    (name: '书名', author: '作者', intro: '简介'),
  ];
}

final class _FakePublicTextFetch implements PublicTextFetchPort {
  const _FakePublicTextFetch();

  @override
  Future<String> fetch(String url, {String userAgent = ''}) async => '';
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

  List<BookshelfListEntry>? receivedEntries;
  List<BookSource>? receivedSources;

  @override
  Future<({int added, int skipped, int failed})> importBookshelfEntries(
    List<BookshelfListEntry> entries, {
    required List<BookSource> sources,
    void Function(int index, int total, String status)? onProgress,
  }) async {
    receivedEntries = List<BookshelfListEntry>.of(entries);
    receivedSources = List<BookSource>.of(sources);
    onProgress?.call(1, entries.length, '搜索 ${entries.single.name}');
    return (added: 1, skipped: 0, failed: 0);
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

void main() {
  testWidgets('pastes trimmed text through the clipboard port', (tester) async {
    await tester.pumpWidget(
      _withProviders(
        sourceProvider: await _createSourceProvider(),
        clipboard: _FakeClipboardPort('  [ {"name":"书名"} ]  '),
        child: const MaterialApp(home: Scaffold(body: ImportBookshelfDialog())),
      ),
    );

    await tester.tap(find.text('粘贴'));
    await tester.pump();

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller!.text, '[ {"name":"书名"} ]');
  });

  testWidgets('imports entries with sources from the shared SourceController', (
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
        listPort: _FakeBookshelfListPort(),
        child: const MaterialApp(home: Scaffold(body: ImportBookshelfDialog())),
      ),
    );

    await tester.enterText(find.byType(TextField), '[{"name":"书名"}]');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(bookProvider.receivedEntries, [
      (name: '书名', author: '作者', intro: '简介'),
    ]);
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
  required Widget child,
  ClipboardPort? clipboard,
  BookshelfListPort? listPort,
  BookProvider? bookProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SourceProvider>.value(value: sourceProvider),
      if (bookProvider != null)
        ChangeNotifierProvider<BookProvider>.value(value: bookProvider),
      Provider<ClipboardPort>.value(
        value: clipboard ?? _FakeClipboardPort(null),
      ),
      if (listPort != null) Provider<BookshelfListPort>.value(value: listPort),
      Provider<PublicTextFetchPort>.value(value: const _FakePublicTextFetch()),
      Provider<AppLogPort>.value(value: const _FakeAppLog()),
    ],
    child: child,
  );
}
