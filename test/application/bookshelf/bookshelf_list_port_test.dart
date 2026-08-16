import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_list_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/ports/public_text_fetch_port.dart';

final class _FakeBookshelfListPort implements BookshelfListPort {
  _FakeBookshelfListPort(this.input);

  final String input;
  List<Book>? exported;

  @override
  Future<String?> exportBooks(List<Book> books) async {
    exported = books;
    return 'bookshelf.json';
  }

  @override
  Future<String?> pickFileText() async => input;

  @override
  Future<String> resolveInput(
    String value, {
    required PublicTextFetchPort fetchPort,
  }) async => value;

  @override
  List<BookshelfListEntry> parseEntries(String text) => [
    (name: '书名', author: '作者', intro: '简介'),
  ];
}

void main() {
  test(
    'port keeps the bookshelf entry contract independent of legacy IO',
    () async {
      final port = _FakeBookshelfListPort('[{"name":"书名"}]');

      expect(await port.pickFileText(), '[{"name":"书名"}]');
      expect(port.parseEntries('ignored').single, (
        name: '书名',
        author: '作者',
        intro: '简介',
      ));
    },
  );
}
