import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/chapter_content_cache_port.dart';
import 'package:legado_flutter/help/content_processor.dart';
import 'package:legado_flutter/model/read_book.dart';
import 'package:legado_flutter/models/book.dart';
import 'package:legado_flutter/models/book_source.dart';
import 'package:legado_flutter/services/book_source_service.dart';

void main() {
  late _FakeCache cache;
  late Book book;

  setUp(() {
    cache = _FakeCache();
    book = Book(id: 'book', name: '测试书');
    ReadBook.instance.reset();
    ReadBook.instance.configure(
      sourceService: _FakeSourceService(),
      processor: ContentProcessor.instance,
      contentCache: cache,
    );
  });

  tearDown(ReadBook.instance.reset);

  test(
    'raw chapter cache reads and writes through ChapterContentCachePort',
    () async {
      const raw = '第一行\r\n\r\n第二行';
      cache.values[cache.key(book.id, 'chapter')] = raw;
      ReadBook.instance.open(
        currentBook: book,
        source: _source,
        chapterList: const [],
      );

      expect(await ReadBook.instance.readRawChapterCache('chapter'), raw);

      const replacement = '编辑后的原文\n保留断行';
      await ReadBook.instance.writeRawChapterCache('chapter', replacement);
      expect(cache.values[cache.key(book.id, 'chapter')], replacement);
      expect(cache.reads, [cache.key(book.id, 'chapter')]);
      expect(cache.writes, [cache.key(book.id, 'chapter')]);
    },
  );

  test(
    'raw cache methods use an explicit book id without opening a session',
    () async {
      const raw = '指定书籍原文';
      await ReadBook.instance.writeRawChapterCache(
        'chapter',
        raw,
        bookId: 'explicit-book',
      );

      expect(
        await ReadBook.instance.readRawChapterCache(
          'chapter',
          bookId: 'explicit-book',
        ),
        raw,
      );
    },
  );
}

final _source = BookSource(
  bookSourceUrl: 'https://example.com',
  bookSourceName: '测试源',
);

class _FakeCache implements ChapterContentCachePort {
  final values = <String, String>{};
  final reads = <String>[];
  final writes = <String>[];

  String key(String bookId, String chapterId) => '$bookId\u0000$chapterId';

  @override
  Future<String?> get(String bookId, String chapterId) async {
    final value = key(bookId, chapterId);
    reads.add(value);
    return values[value];
  }

  @override
  Future<void> save(String bookId, String chapterId, String content) async {
    final value = key(bookId, chapterId);
    writes.add(value);
    values[value] = content;
  }

  @override
  Future<void> delete(String bookId, String chapterId) async {
    values.remove(key(bookId, chapterId));
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

class _FakeSourceService extends BookSourceService {}
