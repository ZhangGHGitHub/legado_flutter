import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/infrastructure/bookshelf/bookshelf_display_port_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reads existing bookshelf config and manual order', () async {
    SharedPreferences.setMockInitialValues({
      'bookGroupStyle': 1,
      'bookshelfLayout': 3,
      'bookshelfSort': 3,
      'shelf_book_order': ['book-2', 'book-1'],
    });
    const port = SharedPreferencesBookshelfDisplayPortAdapter();

    final config = await port.loadConfig();

    expect(config.bookGroupStyle, 1);
    expect(config.bookshelfLayout, 3);
    expect(config.bookshelfSort, 3);
    expect(await port.loadBookOrder(), ['book-2', 'book-1']);
  });
}
