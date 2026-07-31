import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/reader/book_reader_prefs_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/features/reader/reader_page.dart';

import '../../helpers/fake_book_reader_prefs_port.dart';

void main() {
  test('test hosts can explicitly inject the book reader preference fake', () {
    final prefs = FakeBookReaderPrefsPort();
    final chapter = Chapter(
      id: 'chapter-1',
      bookId: 'book-1',
      title: '第一章',
      index: 0,
      url: '',
    );
    final page = ReaderPage(
      book: Book(id: 'book-1', name: '测试书'),
      chapter: chapter,
      allChapters: [chapter],
      prefs: prefs,
    );

    expect(page.prefs, same(prefs));
    expect(page.prefs, isA<BookReaderPrefsPort>());
  });
}
