import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_local_book_port.dart';
import 'package:legado_flutter/domain/book/book.dart';

final class _FakeBookshelfLocalBookPort implements BookshelfLocalBookPort {
  _FakeBookshelfLocalBookPort(this.book);

  final Book? book;

  @override
  Future<Book?> importLocalBook() async => book;
}

void main() {
  test('local book port keeps nullable import result', () async {
    final book = Book(id: 'local-1', name: '本地书', author: '作者');
    final port = _FakeBookshelfLocalBookPort(book);

    expect(await port.importLocalBook(), same(book));
  });

  test('local import error keeps user-facing message', () {
    const error = BookshelfLocalBookImportException('文件过大');

    expect(error.toString(), '文件过大');
    expect(error.message, '文件过大');
  });
}
