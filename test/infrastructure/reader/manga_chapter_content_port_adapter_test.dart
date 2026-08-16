import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/infrastructure/reader/manga_chapter_content_port_adapter.dart';

void main() {
  test('forwards the book and chapter to the manga content loader', () async {
    const book = Book(id: 'book-1', name: '测试漫画');
    const chapter = Chapter(
      id: 'chapter-1',
      bookId: 'book-1',
      title: '第一章',
      index: 0,
      url: 'https://source.example/chapter-1',
    );
    Book? loadedBook;
    Chapter? loadedChapter;

    final adapter = MangaChapterContentPortAdapter(
      loadChapterContent: ({required book, required chapter}) async {
        loadedBook = book;
        loadedChapter = chapter;
        return '<img src="page-1.jpg">';
      },
    );

    expect(
      await adapter.loadChapterContent(book: book, chapter: chapter),
      '<img src="page-1.jpg">',
    );
    expect(loadedBook, same(book));
    expect(loadedChapter, same(chapter));
  });

  test('does not replace loader exceptions', () async {
    final error = StateError('未找到书源，无法加载漫画页');
    final adapter = MangaChapterContentPortAdapter(
      loadChapterContent: ({required book, required chapter}) async {
        throw error;
      },
    );

    await expectLater(
      adapter.loadChapterContent(
        book: const Book(id: 'book-1', name: '测试漫画'),
        chapter: const Chapter(
          id: 'chapter-1',
          bookId: 'book-1',
          title: '第一章',
          index: 0,
          url: 'chapter-1',
        ),
      ),
      throwsA(same(error)),
    );
  });
}
