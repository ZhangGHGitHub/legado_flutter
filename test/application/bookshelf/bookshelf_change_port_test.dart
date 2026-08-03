import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_change_port.dart';
import 'package:legado_flutter/domain/book/book.dart';

void main() {
  test(
    'BookshelfChangeBus publishes monotonically increasing revisions',
    () async {
      final bus = BookshelfChangeBus();
      addTearDown(bus.dispose);
      final changes = <BookshelfChange>[];
      final subscription = bus.changes.listen(changes.add);
      addTearDown(subscription.cancel);
      final book = const Book(id: 'book-1', name: '示例书');

      bus.notifyChanged([book]);
      bus.notifyChanged(const []);
      await Future<void>.delayed(Duration.zero);

      expect(changes.map((change) => change.revision), [1, 2]);
      expect(changes.first.books, [book]);
      expect(bus.revision, 2);
      expect(bus.latest?.books, isEmpty);
    },
  );
}
