import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/infrastructure/bookshelf/bookshelf_display_state_port_adapter.dart';

void main() {
  test('forwards the active update count and provider notifications', () {
    final notifier = ChangeNotifier();
    addTearDown(notifier.dispose);
    var activeCount = 2;
    final adapter = BookshelfDisplayStatePortAdapter(
      listenable: notifier,
      isLoading: () => false,
      isBookUpdating: (_) => false,
      reload: () async {},
      shelfUpdateActiveCount: () => activeCount,
    );
    var notifications = 0;
    adapter.addListener(() => notifications++);

    expect(adapter.shelfUpdateActiveCount, 2);
    activeCount = 1;
    notifier.notifyListeners();

    expect(adapter.shelfUpdateActiveCount, 1);
    expect(notifications, 1);
  });
}
