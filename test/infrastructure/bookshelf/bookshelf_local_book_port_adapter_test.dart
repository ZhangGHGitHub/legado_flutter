import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_local_book_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/infrastructure/bookshelf/bookshelf_local_book_port_adapter.dart';
import 'package:legado_flutter/services/local_book_service.dart';

void main() {
  test('adapter forwards imported book', () async {
    final book = Book(id: 'local-1', name: '本地书', author: '作者');
    final port = BookshelfLocalBookPortAdapter(() async => book);

    expect(await port.importLocalBook(), same(book));
  });

  test('adapter maps legacy import error without changing message', () async {
    final port = BookshelfLocalBookPortAdapter(() async {
      throw LocalBookImportException('文件过大');
    });

    expect(
      () => port.importLocalBook(),
      throwsA(
        isA<BookshelfLocalBookImportException>().having(
          (error) => error.message,
          'message',
          '文件过大',
        ),
      ),
    );
  });
}
