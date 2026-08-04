import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/infrastructure/reader/reader_image_headers_port_adapter.dart';

void main() {
  test('forwards the book to the existing image headers loader', () async {
    const book = Book(id: 'book-1', name: '测试书');
    Book? loadedBook;
    final adapter = ReaderImageHeadersPortAdapter(
      imageHeadersForBook: (book) async {
        loadedBook = book;
        return const {'Referer': 'https://source.example/'};
      },
    );

    expect(await adapter.imageHeadersForBook(book), {
      'Referer': 'https://source.example/',
    });
    expect(loadedBook, same(book));
  });

  test('preserves loader failures', () async {
    final adapter = ReaderImageHeadersPortAdapter(
      imageHeadersForBook: (_) async =>
          Future<Map<String, String>>.error(StateError('headers failed')),
    );

    expect(
      () => adapter.imageHeadersForBook(const Book(id: 'book-1', name: '测试书')),
      throwsA(isA<StateError>()),
    );
  });
}
