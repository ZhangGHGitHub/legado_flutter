import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/public_text_fetch_port.dart';
import 'package:legado_flutter/services/bookshelf_list_io.dart';

class _FakePublicTextFetchPort implements PublicTextFetchPort {
  _FakePublicTextFetchPort(this.body);

  final String body;
  String? requestedUrl;

  @override
  Future<String> fetch(String url, {String userAgent = ''}) async {
    requestedUrl = url;
    return body;
  }
}

void main() {
  test('resolveInput fetches URL through the injected port', () async {
    final port = _FakePublicTextFetchPort('[{"name":"书名"}]');

    final result = await BookshelfListIo.resolveInput(
      'https://list.example/books.json',
      fetchPort: port,
    );

    expect(port.requestedUrl, 'https://list.example/books.json');
    expect(BookshelfListIo.parseEntries(result).single.name, '书名');
  });

  test('resolveInput keeps inline JSON without a network request', () async {
    final port = _FakePublicTextFetchPort('unused');

    final result = await BookshelfListIo.resolveInput(
      '[{"bookName":"本地书单","author":"作者"}]',
      fetchPort: port,
    );

    expect(port.requestedUrl, isNull);
    final entry = BookshelfListIo.parseEntries(result).single;
    expect(entry.name, '本地书单');
    expect(entry.author, '作者');
  });

  test('fetchUrl rejects an empty response', () async {
    final port = _FakePublicTextFetchPort('  ');

    await expectLater(
      BookshelfListIo.fetchUrl(
        'https://list.example/empty.json',
        fetchPort: port,
      ),
      throwsA(isA<FormatException>()),
    );
  });
}
