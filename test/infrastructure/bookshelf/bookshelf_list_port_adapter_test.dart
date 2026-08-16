import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/public_text_fetch_port.dart';
import 'package:legado_flutter/infrastructure/bookshelf/bookshelf_list_port_adapter.dart';

final class _FakePublicTextFetchPort implements PublicTextFetchPort {
  String? requestedUrl;

  @override
  Future<String> fetch(String url, {String userAgent = ''}) async {
    requestedUrl = url;
    return '[{"bookName":"远程书","author":"作者"}]';
  }
}

void main() {
  test('adapter preserves URL resolution and legacy entry aliases', () async {
    const port = BookshelfListPortAdapter();
    final fetch = _FakePublicTextFetchPort();

    final raw = await port.resolveInput(
      'https://list.example/books.json',
      fetchPort: fetch,
    );

    expect(fetch.requestedUrl, 'https://list.example/books.json');
    expect(port.parseEntries(raw), [(name: '远程书', author: '作者', intro: '')]);
  });

  test('adapter keeps inline JSON local', () async {
    const port = BookshelfListPortAdapter();
    final fetch = _FakePublicTextFetchPort();

    final raw = await port.resolveInput(
      '[{"name":"本地书","intro":"简介"}]',
      fetchPort: fetch,
    );

    expect(fetch.requestedUrl, isNull);
    expect(port.parseEntries(raw).single, (
      name: '本地书',
      author: '',
      intro: '简介',
    ));
  });
}
