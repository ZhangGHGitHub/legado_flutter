import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/infrastructure/reader/reader_chapter_content_port_adapter.dart';

void main() {
  test('forwards the book and chapter to cached content loading', () async {
    const book = Book(id: 'book-1', name: '测试书');
    const chapter = Chapter(
      id: 'chapter-1',
      bookId: 'book-1',
      title: '第一章',
      index: 0,
      url: 'https://source.example/chapter-1',
    );
    Book? loadedBook;
    Chapter? loadedChapter;

    final adapter = ReaderChapterContentPortAdapter(
      loadChapterContent: ({required book, required chapter}) async {
        loadedBook = book;
        loadedChapter = chapter;
        return '正文';
      },
    );

    expect(
      await adapter.loadChapterContent(book: book, chapter: chapter),
      '正文',
    );
    expect(loadedBook, book);
    expect(loadedChapter, chapter);
  });
}
