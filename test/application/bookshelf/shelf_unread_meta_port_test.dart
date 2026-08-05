import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/bookshelf/shelf_unread_meta_port.dart';
import 'package:legado_flutter/infrastructure/bookshelf/shelf_unread_meta_port_adapter.dart';

final class _ChangeNotifierMetaSource extends ChangeNotifier {
  ({int count, int? durIndex})? value;
}

void main() {
  test('adapter delegates metadata reads and notifications', () {
    final source = _ChangeNotifierMetaSource()
      ..value = (count: 12, durIndex: 3);
    final port = ShelfUnreadMetaPortAdapter(
      listenable: source,
      metaFor: (_) => source.value,
    );
    var notifications = 0;
    port.addListener(() => notifications++);

    expect(port.metaFor('book-1'), (count: 12, durIndex: 3));
    source.notifyListeners();
    expect(notifications, 1);
  });

  test('empty port returns no metadata', () {
    expect(const EmptyShelfUnreadMetaPort().metaFor('book-1'), isNull);
  });
}
