import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/core_api.dart';
import 'package:legado_flutter/application/mock_core_api.dart';
import 'package:legado_flutter/application/real_core_api.dart';
import 'package:legado_flutter/application/book/book_provider_source_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/domain/repositories/book_repository.dart';
import 'package:legado_flutter/domain/repositories/book_source_repository.dart';
import 'package:legado_flutter/domain/source/book_source.dart';

void main() {
  group('CoreApi contract', () {
    test(
      'MockCoreApi returns stable sample data and empty keyword semantics',
      () async {
        final api = MockCoreApi();

        expect((await api.getBookshelf()).single.name, '示例书籍');
        expect(
          await api.searchBooks(sourceUrl: 'mock://source', keyword: ''),
          isEmpty,
        );
        expect(
          (await api.searchBooks(
            sourceUrl: 'mock://source',
            keyword: '书',
          )).single.name,
          '示例搜索结果',
        );
      },
    );

    test('RealCoreApi maps repository and source port values', () async {
      final source = BookSource(
        bookSourceUrl: 'https://source.example',
        bookSourceName: '示例书源',
      );
      final api = RealCoreApi(
        books: _FakeBookRepository(),
        sources: _FakeBookSourceRepository(source),
        sourceApi: _FakeSourcePort(),
      );

      expect((await api.getBookshelf()).single.id, 'book-1');
      final results = await api.searchBooks(
        sourceUrl: source.bookSourceUrl,
        keyword: '关键词',
      );
      expect(results.single.bookUrl, 'https://source.example/book-1');
    });

    test('RealCoreApi classifies invalid source input', () async {
      final api = RealCoreApi(
        books: _FakeBookRepository(),
        sources: _FakeBookSourceRepository(null),
        sourceApi: _FakeSourcePort(),
      );

      await expectLater(
        api.searchBooks(sourceUrl: '', keyword: '关键词'),
        throwsA(
          isA<CoreApiException>().having(
            (error) => error.kind,
            'kind',
            CoreApiErrorKind.validation,
          ),
        ),
      );
    });
  });
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
  _FakeBookSourceRepository(this.source);

  final BookSource? source;

  @override
  Future<List<BookSource>> getAll() async => source == null ? [] : [source!];
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
  ) async => [
    {'name': '结果', 'author': '作者', 'bookUrl': '${source.bookSourceUrl}/book-1'},
  ];

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
