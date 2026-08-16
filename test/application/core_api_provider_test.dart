import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/book/book_provider_source_port.dart';
import 'package:legado_flutter/application/core_api.dart';
import 'package:legado_flutter/application/core_api_provider.dart';
import 'package:legado_flutter/application/mock_core_api.dart';
import 'package:legado_flutter/application/real_core_api.dart';
import 'package:legado_flutter/application/source_management/source_notifier.dart';
import 'package:legado_flutter/bootstrap/app_composition_root.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/domain/repositories/book_repository.dart';
import 'package:legado_flutter/domain/repositories/book_source_repository.dart';
import 'package:legado_flutter/domain/search_result_item.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/providers/source_provider.dart';
import 'package:provider/provider.dart' as provider;

import 'source_management/source_controller_test.dart' as source_fixtures;

void main() {
  group('coreApiProvider', () {
    test('defaults to MockCoreApi for Rust-free UI development', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(coreApiProvider), isA<MockCoreApi>());
    });

    test('allows replacing the implementation through its Notifier', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final api = _TestCoreApi();

      container.read(coreApiNotifierProvider.notifier).replace(api);

      expect(container.read(coreApiProvider), same(api));
    });

    test('supports direct provider override for isolated consumers', () {
      final api = _TestCoreApi();
      final container = ProviderContainer(
        overrides: [coreApiProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);

      expect(container.read(coreApiProvider), same(api));
    });

    testWidgets('composition root injects RealCoreApi into ProviderScope', (
      tester,
    ) async {
      CoreApi? observed;

      await tester.pumpWidget(
        AppCompositionRoot.withCoreApi(
          bookRepository: _FakeBookRepository(),
          sourceRepository: _FakeBookSourceRepository(),
          bookProviderSourcePort: _FakeSourcePort(),
          child: Consumer(
            builder: (context, ref, child) {
              observed = ref.read(coreApiProvider);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(observed, isA<RealCoreApi>());
      expect(observed, isNot(isA<MockCoreApi>()));
      expect((await observed!.getBookshelf()).single.id, 'book-1');
    });

    testWidgets(
      'composition root shares SourceProvider controller with Riverpod',
      (tester) async {
        final sourceProvider = SourceProvider(
          repository: _FakeBookSourceRepository(),
          validationPort: source_fixtures.createValidationPortForNotifierTest(),
          sourceService: source_fixtures.createSourceServiceForNotifierTest(),
        );
        addTearDown(sourceProvider.dispose);
        Object? observedController;

        await tester.pumpWidget(
          provider.ChangeNotifierProvider<SourceProvider>.value(
            value: sourceProvider,
            child: AppCompositionRoot.withCoreApi(
              bookRepository: _FakeBookRepository(),
              sourceRepository: _FakeBookSourceRepository(),
              bookProviderSourcePort: _FakeSourcePort(),
              child: Consumer(
                builder: (context, ref, child) {
                  observedController = ref.read(sourceControllerProvider);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );

        expect(observedController, same(sourceProvider.controller));
      },
    );
  });
}

class _TestCoreApi implements CoreApi {
  @override
  Future<List<Book>> getBookshelf() async => const [];

  @override
  Future<List<SearchResultItem>> searchBooks({
    required String sourceUrl,
    required String keyword,
  }) async => const [];
}

class _FakeBookRepository implements BookRepository {
  @override
  Future<List<Book>> getAll() async => [Book(id: 'book-1', name: '书')];

  @override
  Future<void> clearChapterContent(Chapter chapter) async {}

  @override
  Future<void> delete(String bookId) async {}

  @override
  Future<String?> getChapterContent(String chapterId) async => null;

  @override
  Future<List<Chapter>> getChapters(String bookId) async => [];

  @override
  Future<void> insert(Book book) async {}

  @override
  Future<void> insertChapters(List<Chapter> chapters) async {}

  @override
  Future<void> saveChapterContent(String chapterId, String content) async {}

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
  Future<void> updateProgress(
    String bookId,
    double progress,
    String? chapter, {
    int pageIndex = 0,
  }) async {}
}

class _FakeBookSourceRepository implements BookSourceRepository {
  @override
  Future<List<BookSource>> getAll() async => [
    BookSource(bookSourceUrl: 'https://source.example', bookSourceName: '示例书源'),
  ];

  @override
  Future<List<BookSource>> getEnabled() async => getAll();

  @override
  Future<void> delete(String url) async {}

  @override
  Future<void> toggle(String url, bool enabled) async {}

  @override
  Future<void> update(BookSource source) async {}

  @override
  Future<void> upsert(BookSource source) async {}

  @override
  Future<void> upsertAll(List<BookSource> sources) async {}
}

class _FakeSourcePort implements BookProviderSourcePort {
  @override
  Future<List<Map<String, String>>> search(
    BookSource source,
    String keyword,
  ) async => const [];

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

  @override
  Future<Map<String, String>> getBookInfo(
    BookSource source,
    String bookUrl,
  ) async => {};

  @override
  Future<List<Chapter>> getChapters(
    Book book, {
    required BookSource source,
  }) async => [];

  @override
  List<Book> resultsToBooks(
    List<Map<String, String>> results,
    String sourceUrl,
  ) => [];
}
