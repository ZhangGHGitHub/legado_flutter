import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/infrastructure/book/book_metadata_port_adapter.dart';

void main() {
  test('delegates cover writes and preserves returned book', () async {
    const book = Book(id: 'book-1', name: '测试书');
    final updated = book.copyWith(coverUrl: 'https://cover.example/new.jpg');
    Book? receivedBook;
    String? receivedCover;
    final port = BookMetadataPortAdapter(
      updateCover: (value, coverUrl) async {
        receivedBook = value;
        receivedCover = coverUrl;
        return updated;
      },
      updateCustomCover: (book, customCoverUrl) async =>
          book.copyWith(customCoverUrl: customCoverUrl),
      updateBookDetails:
          (_, {required name, required author, required description}) async =>
              null,
    );

    expect(await port.updateCover(book, updated.coverUrl), updated);
    expect(receivedBook, book);
    expect(receivedCover, updated.coverUrl);
  });

  test('delegates normalized detail arguments and return value', () async {
    const updated = Book(id: 'book-1', name: '新书名', author: '新作者');
    String? bookId;
    String? receivedName;
    String? receivedAuthor;
    String? receivedDescription;
    final port = BookMetadataPortAdapter(
      updateCover: (book, coverUrl) async => book,
      updateCustomCover: (book, customCoverUrl) async => book,
      updateBookDetails:
          (
            id, {
            required String name,
            required String author,
            required String description,
          }) async {
            bookId = id;
            receivedName = name;
            receivedAuthor = author;
            receivedDescription = description;
            return updated;
          },
    );

    expect(
      await port.updateBookDetails(
        'book-1',
        name: ' 新书名 ',
        author: ' 新作者 ',
        description: ' 新简介 ',
      ),
      updated,
    );
    expect(bookId, 'book-1');
    expect(receivedName, ' 新书名 ');
    expect(receivedAuthor, ' 新作者 ');
    expect(receivedDescription, ' 新简介 ');
  });
}
