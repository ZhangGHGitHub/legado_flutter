import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
          Provider<BookSourceSearchPort>.value(value: const _EmptySearchPort()),
        ],
        child: MaterialApp(home: BookInfoPage(book: book)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('共享书源'), findsOneWidget);
  });
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
  Future<void> updateCover(String bookId, String coverUrl) async {}

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
