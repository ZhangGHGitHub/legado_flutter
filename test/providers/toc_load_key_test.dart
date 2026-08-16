import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/providers/book_provider.dart';

void main() {
  test('directory load key is isolated by book and source', () {
    final first = BookProvider.tocLoadKey(
      bookId: 'book-1',
      sourceUrl: 'https://source-a.example',
    );
    final otherSource = BookProvider.tocLoadKey(
      bookId: 'book-1',
      sourceUrl: 'https://source-b.example',
    );
    final otherBook = BookProvider.tocLoadKey(
      bookId: 'book-2',
      sourceUrl: 'https://source-a.example',
    );

    expect(first, isNot(otherSource));
    expect(first, isNot(otherBook));
  });
}
