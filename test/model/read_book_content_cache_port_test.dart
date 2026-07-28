import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/chapter_content_cache_port.dart';
import 'package:legado_flutter/help/content_processor.dart';
import 'package:legado_flutter/model/read_book.dart';
import 'package:legado_flutter/models/book.dart';
import 'package:legado_flutter/models/book_source.dart';
import 'package:legado_flutter/models/chapter.dart';
import 'package:legado_flutter/services/book_source_service.dart';

void main() {
  late _FakeCache cache;
  late _FakeSourceService sourceService;
  late Book book;
  late Chapter chapter;
  late BookSource source;

  setUp(() {
    cache = _FakeCache();
    sourceService = _FakeSourceService();
    book = Book(id: 'book', name: '测试书');
    chapter = Chapter(
      id: 'chapter',
      bookId: book.id,
      title: '第一章',
      index: 0,
      url: 'https://example.com/chapter',
    );
    source = BookSource(
      bookSourceUrl: 'https://example.com',
      bookSourceName: '测试源',
    );
    ReadBook.instance.reset();
    ReadBook.instance.configure(
      sourceService: sourceService,
      processor: ContentProcessor.instance,
      contentCache: cache,
    );
  });

  tearDown(ReadBook.instance.reset);

  test('ReadBook reads through the injected cache port', () async {
    cache.values[cache.key(book.id, chapter.id)] = '缓存正文';
    ReadBook.instance.open(
      currentBook: book,
      source: source,
      chapterList: [chapter],
    );

    expect(
      await ReadBook.instance.loadChapterContent(
        chapter: chapter,
        source: source,
        bookId: book.id,
      ),
      '缓存正文',
    );
    expect(sourceService.calls, 0);
    expect(cache.reads, [cache.key(book.id, chapter.id)]);
  });

  test('ReadBook invalidates through the injected cache port', () async {
    ReadBook.instance.open(
      currentBook: book,
      source: source,
      chapterList: [chapter],
    );
    await ReadBook.instance.invalidateChapterCache(chapter.id, bookId: book.id);

    expect(cache.deletes, [cache.key(book.id, chapter.id)]);
  });
}

class _FakeCache implements ChapterContentCachePort {
  final values = <String, String>{};
  final reads = <String>[];
  final deletes = <String>[];

  String key(String bookId, String chapterId) => '$bookId\u0000$chapterId';

  @override
  Future<String?> get(String bookId, String chapterId) async {
    final value = key(bookId, chapterId);
    reads.add(value);
    return values[value];
  }

  @override
  Future<void> save(String bookId, String chapterId, String content) async {
    values[key(bookId, chapterId)] = content;
  }

  @override
  Future<void> delete(String bookId, String chapterId) async {
    final value = key(bookId, chapterId);
    deletes.add(value);
    values.remove(value);
  }

  @override
  Future<void> clearAll() async => values.clear();

  @override
  Future<void> clearBook(String bookId) async {
    values.removeWhere((key, _) => key.startsWith('$bookId\u0000'));
  }

  @override
  Future<int> clearInvalid(Set<String> validBookIds) async => 0;

  @override
  Future<bool> has(String bookId, String chapterId) async {
    return values.containsKey(key(bookId, chapterId));
  }

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
  Future<({int bytes, int chapterFiles})> stats(String bookId) async {
    return (bytes: 0, chapterFiles: 0);
  }
}

class _FakeSourceService extends BookSourceService {
  var calls = 0;

  @override
  Future<String> getChapterContent(
    String url, {
    required BookSource source,
  }) async {
    calls++;
    return '网络正文';
  }
}
