import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/infrastructure/bookshelf/bookshelf_membership_port_adapter.dart';

void main() {
  test('exposes an immutable snapshot and forwards listeners', () {
    final notifier = ChangeNotifier();
    addTearDown(notifier.dispose);
    const book = Book(id: 'book-1', name: '测试书');
    final adapter = BookshelfMembershipPortAdapter(
      listenable: notifier,
      books: () => [book],
    );
    var notifications = 0;

    adapter.addListener(() => notifications++);
    expect(adapter.books, [book]);
    expect(() => adapter.books.add(book), throwsUnsupportedError);
    notifier.notifyListeners();
    expect(notifications, 1);
  });
}
