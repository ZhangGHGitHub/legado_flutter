import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/database/dao/book_dao.dart';
import 'package:legado_flutter/domain/ports/chapter_content_cache_port.dart';
import 'package:legado_flutter/model/read_book.dart';
import 'package:legado_flutter/models/book.dart';
import 'package:legado_flutter/models/book_source.dart';
import 'package:legado_flutter/models/chapter.dart';
import 'package:legado_flutter/providers/book_provider.dart';
import 'package:legado_flutter/services/book_source_service.dart';

class _SpyCache implements ChapterContentCachePort {
  int clearInvalidCalls = 0;
  Set<String>? lastValidBookIds;
  final List<String> clearedBookIds = [];
  final List<String> listedBookIds = [];
  Set<String> listedChapterIds = {};

  @override
  Future<String?> get(String bookId, String chapterId) async => null;

  @override
  Future<void> save(String bookId, String chapterId, String content) async {}

  @override
  Future<void> delete(String bookId, String chapterId) async {}

  @override
  Future<void> clearAll() async {}

  @override
  Future<void> clearBook(String bookId) async {
    clearedBookIds.add(bookId);
  }

  @override
  Future<int> clearInvalid(Set<String> validBookIds) async {
    clearInvalidCalls++;
    lastValidBookIds = Set<String>.from(validBookIds);
    return 0;
  }

  @override
  Future<bool> has(String bookId, String chapterId) async => false;

  @override
  Future<Set<String>> listChapterIds(String bookId) async {
    listedBookIds.add(bookId);
    return Set<String>.from(listedChapterIds);
  }

  @override
  String sanitizeChapterId(String chapterId) => 'normalized:$chapterId';

  @override
  Future<Map<String, int>> mapWordCounts(
    String bookId, {
    Set<String>? chapterIds,
  }) async => {};

  @override
  Future<({int bytes, int chapterFiles})> stats(String bookId) async =>
      (bytes: 0, chapterFiles: 0);
}

class _BookDao extends BookDao {
  _BookDao(this.book, this.chapters);

  Book book;
  List<Chapter> chapters;
  final List<String> deletedBookIds = [];

  @override
  Future<void> insert(Book value) async {
    book = value;
  }

  @override
  Future<List<Book>> getAll() async => [book];

  @override
  Future<void> delete(String bookId) async {
    deletedBookIds.add(bookId);
  }

  @override
  Future<List<Chapter>> getChapters(String bookId) async =>
      List<Chapter>.from(chapters);

  @override
  Future<void> insertChapters(List<Chapter> value) async {
    chapters = List<Chapter>.from(value);
  }
}

class _SourceService extends BookSourceService {
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
}

BookSource _source() =>
    BookSource(bookSourceUrl: 'cache-port-source', bookSourceName: '缓存端口');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(ReadBook.instance.reset);

  test('cache lifecycle calls use the injected port', () async {
    final book = Book(id: 'book-1', name: '测试书');
    final cache = _SpyCache();
    final dao = _BookDao(book, [
      Chapter(
        id: 'chapter-1',
        bookId: book.id,
        title: '第一章',
        index: 0,
        url: '/chapter-1',
      ),
    ]);
    final provider = BookProvider(
      repository: dao,
      sourceService: _SourceService(),
      contentCache: cache,
    );

    await provider.loadBooks();
    expect(cache.clearInvalidCalls, 1);
    expect(cache.lastValidBookIds, {book.id});

    await provider.removeBook(book.id);
    expect(dao.deletedBookIds, [book.id]);
    expect(cache.clearedBookIds, [book.id]);
  });

  test(
    'chapter cache metadata uses injected normalization and listing',
    () async {
      final book = Book(id: 'book-1', name: '测试书');
      final chapter = Chapter(
        id: 'chapter-1',
        bookId: book.id,
        title: '第一章',
        index: 0,
        url: '/chapter-1',
      );
      final cache = _SpyCache()
        ..listedChapterIds = {'normalized:${chapter.id}'};
      final provider = BookProvider(
        repository: _BookDao(book, [chapter]),
        sourceService: _SourceService(),
        contentCache: cache,
      );

      await provider.loadBooks();
      await provider.loadChapters(book, source: _source());
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(cache.listedBookIds, [book.id]);
      expect(provider.currentChapters.single.isDownloaded, isTrue);
    },
  );
}
