import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/infrastructure/book/book_read_status_port_adapter.dart';

void main() {
  test('阅读状态适配器转发书籍和轮次', () async {
    Book? receivedBook;
    int? receivedIteration;
    final port = BookReadStatusPortAdapter(
      update: (book, readIteration) async {
        receivedBook = book;
        receivedIteration = readIteration;
      },
    );
    const book = Book(id: 'book-1', name: '测试书');

    await port.updateReadIteration(book, 3);

    expect(receivedBook, book);
    expect(receivedIteration, 3);
  });
}
