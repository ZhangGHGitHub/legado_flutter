import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/database/dao/book_dao.dart';
import 'package:legado_flutter/domain/ports/chapter_content_cache_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/providers/book_provider.dart';
import '../helpers/book_source_service_test_factory.dart';

class _MemoryBookDao extends BookDao {
  final List<Book> books = [];

  @override
  Future<List<Book>> getAll() async => List<Book>.from(books);

  @override
  Future<void> insert(Book book) async {
    books.removeWhere((item) => item.id == book.id);
    books.add(book);
  }

  @override
  Future<List<Chapter>> getChapters(String bookId) async => const [];
}

class _BookInfoService extends TestBookSourceService {
  _BookInfoService(this.info);

  final Map<String, String> info;

  @override
  Future<Map<String, String>> getBookInfo(
    BookSource source,
    String bookUrl,
  ) async {
    return Map<String, String>.from(info);
  }
}

class _NoopContentCache implements ChapterContentCachePort {
  const _NoopContentCache();

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
  }) async => <String, int>{};

  @override
  Future<({int bytes, int chapterFiles})> stats(String bookId) async =>
      (bytes: 0, chapterFiles: 0);
}

BookSource _source() => BookSource(
  bookSourceUrl: 'https://source.example',
  bookSourceName: '字段契约测试书源',
);

const _detailUrl = 'https://source.example/book/42';
const _tocUrl = 'https://source.example/book/42/chapters';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('resolveBookFromUrl keeps sourceUrl and tocUrl separate', () async {
    final provider = BookProvider(
      repository: _MemoryBookDao(),
      contentCache: const _NoopContentCache(),
      sourceService: _BookInfoService({
        'name': '字段契约测试书',
        'author': '测试作者',
        'tocUrl': _tocUrl,
      }),
    );

    final book = await provider.resolveBookFromUrl(
      '$_detailUrl,{"origin":"https://source.example"}',
      sources: [_source()],
    );

    expect(book.sourceUrl, _detailUrl);
    expect(book.tocUrl, _tocUrl);
  });

  test('addBooksByUrls persists sourceUrl and tocUrl from details', () async {
    final dao = _MemoryBookDao();
    final provider = BookProvider(
      repository: dao,
      contentCache: const _NoopContentCache(),
      sourceService: _BookInfoService({
        'name': '字段契约测试书',
        'author': '测试作者',
        'tocUrl': _tocUrl,
      }),
    );

    final result = await provider.addBooksByUrls(
      '$_detailUrl,{"origin":"https://source.example"}',
      sources: [_source()],
    );

    expect(result.success, 1);
    expect(result.fail, 0);
    expect(dao.books, hasLength(1));
    expect(dao.books.single.sourceUrl, _detailUrl);
    expect(dao.books.single.tocUrl, _tocUrl);
  });

  test(
    'same-name migration carries the detail tocUrl without replacing sourceUrl',
    () async {
      final dao = _MemoryBookDao();
      final existing = Book(
        id: 'existing-book',
        name: '字段契约测试书',
        author: '测试作者',
        sourceUrl: 'https://old-source.example/book/42',
        bookSourceUrl: 'https://old-source.example',
      );
      await dao.insert(existing);
      final provider = BookProvider(
        repository: dao,
        contentCache: const _NoopContentCache(),
        sourceService: _BookInfoService({
          'name': existing.name,
          'author': existing.author,
          'tocUrl': _tocUrl,
        }),
      );
      await provider.loadBooks();
      expect(provider.books, hasLength(1));

      final result = await provider.addBooksByUrls(
        _detailUrl,
        sources: [_source()],
      );

      expect(result.success, 1);
      expect(dao.books, hasLength(1));
      expect(dao.books.single.sourceUrl, _detailUrl);
      expect(dao.books.single.tocUrl, _tocUrl);
    },
  );
}
