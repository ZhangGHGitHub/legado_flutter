import 'package:flutter_test/flutter_test.dart';

import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/infrastructure/bookshelf/bookshelf_arrange_snapshot_port_adapter.dart';

void main() {
  test(
    'adapter exposes the latest complete bookshelf as an immutable list',
    () {
      var books = <Book>[const Book(id: 'one', name: '第一本')];
      final port = BookshelfArrangeSnapshotPortAdapter(() => books);

      expect(port.books, equals(books));
      expect(
        () => port.books.add(const Book(id: 'two', name: '第二本')),
        throwsUnsupportedError,
      );

      books = [const Book(id: 'two', name: '第二本')];
      expect(port.books.single.id, 'two');
    },
  );
}
