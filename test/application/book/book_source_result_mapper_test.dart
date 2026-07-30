import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/book/book_source_result_mapper.dart';

void main() {
  test('maps source results to books without changing source fields', () {
    final books = mapBookSourceResults([
      {
        'url': 'https://example.com/book/1',
        'name': '示例书',
        'author': '作者',
        'coverUrl': 'https://example.com/cover.jpg',
        'note': '简介',
      },
    ], 'source://demo');

    expect(books, hasLength(1));
    expect(books.single.name, '示例书');
    expect(books.single.author, '作者');
    expect(books.single.coverUrl, 'https://example.com/cover.jpg');
    expect(books.single.sourceUrl, 'https://example.com/book/1');
    expect(books.single.description, '简介');
    expect(books.single.bookSourceUrl, 'source://demo');
    expect(
      books.single.id,
      'source://demo_${'https://example.com/book/1'.hashCode}',
    );
  });

  test('keeps legacy defaults when a source result omits optional fields', () {
    final books = mapBookSourceResults([
      {'url': 'book://empty'},
    ], 'source://demo');

    expect(books.single.name, '未知书名');
    expect(books.single.author, isEmpty);
    expect(books.single.coverUrl, isEmpty);
    expect(books.single.description, isEmpty);
  });
}
