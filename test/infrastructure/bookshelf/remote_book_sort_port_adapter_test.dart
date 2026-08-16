import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/bookshelf/remote_book_sort_port.dart';
import 'package:legado_flutter/domain/remote/webdav_entry.dart';
import 'package:legado_flutter/infrastructure/bookshelf/remote_book_sort_port_adapter.dart';

WebDavEntry _entry(String name, {required bool isDir, required int modified}) =>
    WebDavEntry(
      name: name,
      path: '/books/$name',
      isDir: isDir,
      size: 1,
      lastModified: modified,
    );

void main() {
  test('adapts directory-first time sorting', () {
    const adapter = RemoteBookSortPortAdapter();

    final sorted = adapter.sort(
      [
        _entry('new.txt', isDir: false, modified: 300),
        _entry('folder', isDir: true, modified: 100),
        _entry('old.txt', isDir: false, modified: 100),
      ],
      mode: RemoteBookSortMode.time,
      ascending: false,
    );

    expect(sorted.map((entry) => entry.name), ['folder', 'new.txt', 'old.txt']);
  });
}
