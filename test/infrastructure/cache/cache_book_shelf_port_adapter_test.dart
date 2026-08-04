import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/infrastructure/cache/cache_book_shelf_port_adapter.dart';

void main() {
  test(
    'adapter exposes immutable book snapshots and forwards local reads',
    () async {
      final sourceBooks = <Book>[
        const Book(id: 'book-1', name: '测试书', author: '作者'),
      ];
      final chapter = const Chapter(
        id: 'chapter-1',
        bookId: 'book-1',
        title: '第一章',
        index: 0,
        url: 'https://example.com/chapter-1',
      );
      String? chapterCountId;
      String? localChaptersId;

      final adapter = CacheBookShelfPortAdapter(
        books: () => sourceBooks,
        getChapterCount: (bookId) async {
          chapterCountId = bookId;
          return 1;
        },
        getLocalChapters: (bookId) async {
          localChaptersId = bookId;
          return [chapter];
        },
      );

      final snapshot = adapter.books;
      expect(snapshot, sourceBooks);
      expect(
        () => snapshot.add(const Book(id: 'book-2', name: '另一书')),
        throwsUnsupportedError,
      );

      sourceBooks.clear();
      expect(adapter.books, isEmpty);
      expect(await adapter.getChapterCount('book-1'), 1);
      expect(await adapter.getLocalChapters('book-1'), [chapter]);
      expect(chapterCountId, 'book-1');
      expect(localChaptersId, 'book-1');
    },
  );
}
