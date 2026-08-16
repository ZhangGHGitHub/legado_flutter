import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/remote/webdav_entry.dart';

void main() {
  test('WebDavEntry keeps optional etag and value semantics', () {
    const entry = WebDavEntry(
      name: 'book.txt',
      path: '/books/book.txt',
      isDir: false,
      size: 42,
      lastModified: 100,
      etag: 'etag-1',
    );

    expect(entry, equals(entry.copyWith()));
    expect(entry.copyWith(name: 'other.txt').name, 'other.txt');
    expect(entry.copyWith(etag: null).etag, isNull);
  });
}
