import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/domain/ports/chapter_content_cache_port.dart';
import 'package:legado_flutter/infrastructure/cache/book_cache_export_port_adapter.dart';

void main() {
  test('adapter preserves cached chapter export format and ordering', () async {
    final cache = _FakeChapterContentCache(
      cachedIds: {'chapter-1', 'chapter-2'},
      contents: {
        'book-1\u0000chapter-1': '第一章正文',
        'book-1\u0000chapter-2': '第二章正文',
      },
    );
    final port = BookCacheExportPortAdapter(cache);
    final book = Book(id: 'book-1', name: '测试书', author: '作者');
    final chapters = [
      Chapter(
        id: 'chapter-2',
        bookId: book.id,
        title: '第二章',
        index: 1,
        url: 'https://example.com/2',
      ),
      Chapter(
        id: 'chapter-1',
        bookId: book.id,
        title: '第一章',
        index: 0,
        url: 'https://example.com/1',
      ),
    ];

    final text = await port.buildText(book: book, chapters: chapters);

    expect(text, startsWith('测试书\n作者：作者'));
    expect(text.indexOf('第一章'), lessThan(text.indexOf('第二章')));
    expect(text, contains('第一章正文'));
    expect(text, contains('第二章正文'));
  });

  test(
    'adapter returns empty text when no cached chapter has content',
    () async {
      final port = BookCacheExportPortAdapter(
        _FakeChapterContentCache(cachedIds: {'chapter-1'}),
      );
      final book = Book(id: 'book-2', name: '未缓存');

      expect(
        await port.buildBooksText(
          books: [book],
          loadChapters: (_) async => [
            Chapter(
              id: 'chapter-1',
              bookId: book.id,
              title: '第一章',
              index: 0,
              url: 'https://example.com/1',
            ),
          ],
        ),
        isEmpty,
      );
    },
  );
}

final class _FakeChapterContentCache implements ChapterContentCachePort {
  _FakeChapterContentCache({
    this.cachedIds = const {},
    this.contents = const {},
  });

  final Set<String> cachedIds;
  final Map<String, String> contents;

  @override
  Future<String?> get(String bookId, String chapterId) async =>
      contents['$bookId\u0000$chapterId'];

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
  Future<bool> has(String bookId, String chapterId) async =>
      cachedIds.contains(chapterId);

  @override
  Future<Set<String>> listChapterIds(String bookId) async => cachedIds;

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
