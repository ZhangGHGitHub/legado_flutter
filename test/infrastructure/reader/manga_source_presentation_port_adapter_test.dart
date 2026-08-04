import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/infrastructure/reader/manga_source_presentation_port_adapter.dart';

void main() {
  test('uses the existing source matcher and preserves its source name', () {
    const book = Book(
      id: 'book-1',
      name: '测试漫画',
      bookSourceUrl: 'https://source.example/',
    );
    Book? matchedBook;
    final adapter = MangaSourcePresentationPortAdapter(
      findSourceForBook: (book) {
        matchedBook = book;
        return const BookSource(
          bookSourceUrl: 'https://source.example/',
          bookSourceName: '测试漫画源',
        );
      },
    );

    expect(adapter.sourceNameForBook(book), '测试漫画源');
    expect(matchedBook, same(book));
  });

  test(
    'falls back to the original generic source label when no source matches',
    () {
      final adapter = MangaSourcePresentationPortAdapter(
        findSourceForBook: (_) => null,
      );

      expect(
        adapter.sourceNameForBook(const Book(id: 'book-1', name: '测试漫画')),
        '书源',
      );
    },
  );

  test('preserves source matcher failures', () {
    final adapter = MangaSourcePresentationPortAdapter(
      findSourceForBook: (_) => throw StateError('source lookup failed'),
    );

    expect(
      () => adapter.sourceNameForBook(const Book(id: 'book-1', name: '测试漫画')),
      throwsA(isA<StateError>()),
    );
  });
}
