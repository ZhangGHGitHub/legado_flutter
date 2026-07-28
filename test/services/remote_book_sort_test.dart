import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/remote/webdav_entry.dart';
import 'package:legado_flutter/services/remote_book_sort.dart';

WebDavEntry _entry(
  String name, {
  required bool isDir,
  required int lastModified,
}) {
  return WebDavEntry(
    name: name,
    path: '/books/$name',
    isDir: isDir,
    size: 1,
    lastModified: lastModified,
  );
}

void main() {
  test('remote book default sort keeps directories first by modified time', () {
    final sorted = sortRemoteBookEntries(
      [
        _entry('new.txt', isDir: false, lastModified: 300),
        _entry('folder', isDir: true, lastModified: 100),
        _entry('old.txt', isDir: false, lastModified: 100),
      ],
      mode: RemoteBookSortMode.time,
      ascending: false,
    );

    expect(sorted.map((entry) => entry.name), ['folder', 'new.txt', 'old.txt']);
  });

  test('remote book name sort preserves ascending and descending order', () {
    final entries = [
      _entry('b.txt', isDir: false, lastModified: 100),
      _entry('a.txt', isDir: false, lastModified: 200),
    ];

    expect(
      sortRemoteBookEntries(
        entries,
        mode: RemoteBookSortMode.name,
        ascending: true,
      ).map((entry) => entry.name),
      ['a.txt', 'b.txt'],
    );
    expect(
      sortRemoteBookEntries(
        entries,
        mode: RemoteBookSortMode.name,
        ascending: false,
      ).map((entry) => entry.name),
      ['b.txt', 'a.txt'],
    );
  });
}
