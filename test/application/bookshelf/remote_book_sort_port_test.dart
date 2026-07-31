import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/bookshelf/remote_book_sort_port.dart';

void main() {
  test('declares the stable remote book sort modes', () {
    expect(RemoteBookSortMode.values, [
      RemoteBookSortMode.name,
      RemoteBookSortMode.time,
    ]);
  });
}
