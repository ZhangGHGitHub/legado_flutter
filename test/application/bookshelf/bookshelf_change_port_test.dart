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

  test(
    'BookshelfChangeBus publishes a failed snapshot with its stack trace',
    () async {
      final bus = BookshelfChangeBus();
      addTearDown(bus.dispose);
      final changes = <BookshelfChange>[];
      final subscription = bus.changes.listen(changes.add);
      addTearDown(subscription.cancel);
      final error = StateError('书架读取失败');
      final stackTrace = StackTrace.current;
      final book = const Book(id: 'book-1', name: '示例书');

      bus.notifyFailed(error, stackTrace, books: [book]);
      await Future<void>.delayed(Duration.zero);

      expect(changes.single.revision, 1);
      expect(changes.single.books, [book]);
      expect(changes.single.error, same(error));
      expect(changes.single.stackTrace, same(stackTrace));
      expect(bus.latest?.hasError, isTrue);
    },
  );
}
