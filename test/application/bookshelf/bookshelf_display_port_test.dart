import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_display_port.dart';

void main() {
  test('in-memory display port provides stable empty defaults', () async {
    const port = InMemoryBookshelfDisplayPort();

    expect(await port.loadConfig(), const BookshelfConfig());
    expect(await port.loadBookOrder(), isEmpty);
    expect(port.sortBooks(const [], sortMode: 0, orderIds: []), isEmpty);
  });
}
