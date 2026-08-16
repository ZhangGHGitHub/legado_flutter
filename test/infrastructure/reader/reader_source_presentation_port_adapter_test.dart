import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/infrastructure/reader/reader_source_presentation_port_adapter.dart';

void main() {
  test(
    'uses the existing sourceUrl matcher and prioritizes the source name',
    () {
      const book = Book(
        id: 'book-1',
        name: '测试书',
        bookSourceUrl: 'https://source.example/path',
        sourceUrl: 'https://book.example/detail',
      );
      Book? matchedBook;
      final adapter = ReaderSourcePresentationPortAdapter(
        findSourceForBook: (book) {
          matchedBook = book;
          if (book.bookSourceUrl != 'https://source.example/path') return null;
          return const BookSource(
            bookSourceUrl: 'https://source.example/path',
            bookSourceName: '测试书源',
          );
        },
      );

      expect(adapter.sourceNameForBook(book), '测试书源');
      expect(matchedBook, same(book));
    },
  );

  test(
    'falls back to the preferred source URL host when the source name is empty',
    () {
      const book = Book(
        id: 'book-1',
        name: '测试书',
        bookSourceUrl: 'https://source.example/path',
        sourceUrl: 'https://book.example/detail',
      );
      final adapter = ReaderSourcePresentationPortAdapter(
        findSourceForBook: (_) => const BookSource(
          bookSourceUrl: 'https://source.example/path',
          bookSourceName: '',
        ),
      );

      expect(adapter.sourceNameForBook(book), 'source.example');
    },
  );

  test(
    'uses sourceUrl and preserves an unparseable URL when no source name exists',
    () {
      final adapter = ReaderSourcePresentationPortAdapter(
        findSourceForBook: (_) => null,
      );

      expect(
        adapter.sourceNameForBook(
          const Book(
            id: 'book-1',
            name: '测试书',
            sourceUrl: 'https://fallback.example/book',
          ),
        ),
        'fallback.example',
      );
      expect(
        adapter.sourceNameForBook(
          const Book(id: 'book-2', name: '测试书', sourceUrl: 'not a URL'),
        ),
        'not a URL',
      );
    },
  );

  test(
    'returns an empty label when neither source nor source URL is available',
    () {
      final adapter = ReaderSourcePresentationPortAdapter(
        findSourceForBook: (_) => null,
      );

      expect(
        adapter.sourceNameForBook(const Book(id: 'book-1', name: '测试书')),
        isEmpty,
      );
    },
  );

  test('preserves source matcher failures', () {
    final adapter = ReaderSourcePresentationPortAdapter(
      findSourceForBook: (_) => throw StateError('source lookup failed'),
    );

    expect(
      () => adapter.sourceNameForBook(const Book(id: 'book-1', name: '测试书')),
      throwsA(isA<StateError>()),
    );
  });
}
