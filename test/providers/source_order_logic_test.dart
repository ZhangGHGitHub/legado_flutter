import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
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

  test('move to top uses customOrder when list is shuffled', () {
    final shuffled = [
      BookSource(bookSourceUrl: 'c', bookSourceName: 'c', customOrder: 2),
      BookSource(bookSourceUrl: 'a', bookSourceName: 'a', customOrder: 0),
      BookSource(bookSourceUrl: 'b', bookSourceName: 'b', customOrder: 1),
    ];
    final ordered = sourcesInManualOrder(shuffled);
    expect(ordered.map((s) => s.bookSourceUrl).toList(), ['a', 'b', 'c']);

    final orders = customOrdersAfterMoveToTop(ordered, {'b'});
    expect(orders['b'], 0);
    expect(orders['a'], 1);
    expect(orders['c'], 2);
  });

  test('move to bottom uses customOrder when list is shuffled', () {
    final shuffled = [
      BookSource(bookSourceUrl: 'c', bookSourceName: 'c', customOrder: 2),
      BookSource(bookSourceUrl: 'a', bookSourceName: 'a', customOrder: 0),
      BookSource(bookSourceUrl: 'b', bookSourceName: 'b', customOrder: 1),
    ];
    final ordered = sourcesInManualOrder(shuffled);
    final orders = customOrdersAfterMoveToBottom(ordered, {'b'});
    expect(orders['a'], 0);
    expect(orders['c'], 1);
    expect(orders['b'], 2);
  });
}
