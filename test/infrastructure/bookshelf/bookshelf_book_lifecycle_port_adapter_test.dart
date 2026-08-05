import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/infrastructure/bookshelf/bookshelf_book_lifecycle_port_adapter.dart';

void main() {
  test('书架生命周期适配器转发新增、目录保存和移除', () async {
    final calls = <String>[];
    final adapter = BookshelfBookLifecyclePortAdapter(
      addBook: (book) async => calls.add('add:${book.id}'),
      persistCurrentTocFor: (book) async => calls.add('toc:${book.id}'),
      removeBook: (bookId) async => calls.add('remove:$bookId'),
    );
    const book = Book(id: 'book-1', name: '测试书');

    await adapter.addBook(book);
    await adapter.persistCurrentTocFor(book);
    await adapter.removeBook(book.id);

    expect(calls, ['add:book-1', 'toc:book-1', 'remove:book-1']);
  });
}
