import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_change_port.dart';

void main() {
  test(
    'BookshelfChangeBus publishes monotonically increasing revisions',
    () async {
      final bus = BookshelfChangeBus();
      addTearDown(bus.dispose);
      final revisions = <int>[];
      final subscription = bus.changes.listen(revisions.add);
      addTearDown(subscription.cancel);

      bus.notifyChanged();
      bus.notifyChanged();
      await Future<void>.delayed(Duration.zero);

      expect(revisions, [1, 2]);
      expect(bus.revision, 2);
    },
  );
}
