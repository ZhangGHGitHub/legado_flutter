import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/models/book_source.dart';
import 'package:legado_flutter/providers/source_order.dart';

void main() {
  test('move to top reindexes selected first', () {
    final all = [
      BookSource(bookSourceUrl: 'a', bookSourceName: 'a', customOrder: 0),
      BookSource(bookSourceUrl: 'b', bookSourceName: 'b', customOrder: 1),
      BookSource(bookSourceUrl: 'c', bookSourceName: 'c', customOrder: 2),
    ];
    final orders = customOrdersAfterMoveToTop(all, {'b'});
    expect(orders['b'], 0);
    expect(orders['a'], 1);
    expect(orders['c'], 2);
  });

  test('move to bottom reindexes selected last', () {
    final all = [
      BookSource(bookSourceUrl: 'a', bookSourceName: 'a', customOrder: 0),
      BookSource(bookSourceUrl: 'b', bookSourceName: 'b', customOrder: 1),
      BookSource(bookSourceUrl: 'c', bookSourceName: 'c', customOrder: 2),
    ];
    final orders = customOrdersAfterMoveToBottom(all, {'b'});
    expect(orders['a'], 0);
    expect(orders['c'], 1);
    expect(orders['b'], 2);
  });
}
