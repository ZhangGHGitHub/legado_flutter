import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/infrastructure/bookmark/bookmark_reader_port_adapter.dart';

void main() {
  test(
    'forwards reader lookup and returns immutable chapter snapshots',
    () async {
      const book = Book(id: 'book-1', name: '测试书');
      const source = BookSource(
        bookSourceUrl: 'https://source.example',
        bookSourceName: '测试书源',
      );
      final chapters = [
        const Chapter(
          id: 'chapter-1',
          bookId: 'book-1',
          title: '第一章',
          index: 0,
          url: 'https://source.example/chapter-1',
        ),
      ];
      Book? loadedBook;
      BookSource? loadedSource;

      final adapter = BookmarkReaderPortAdapter(
        findBookById: (bookId) => bookId == book.id ? book : null,
        currentChapters: () => chapters,
        loadChapters: (book, {required source}) async {
          loadedBook = book;
          loadedSource = source;
        },
        getLocalChapters: (_) async => chapters,
      );

      expect(adapter.findBookById('book-1'), book);
      expect(adapter.currentChapters, chapters);
      expect(
        () => adapter.currentChapters.add(chapters.single),
        throwsUnsupportedError,
      );
      await adapter.loadChapters(book, source: source);
      expect(loadedBook, book);
      expect(loadedSource, source);
      expect(await adapter.getLocalChapters(book.id), chapters);
    },
  );
}
