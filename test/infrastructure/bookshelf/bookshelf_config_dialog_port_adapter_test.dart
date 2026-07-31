import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_config_dialog_port.dart';
import 'package:legado_flutter/infrastructure/bookshelf/bookshelf_config_dialog_port_adapter.dart';
import 'package:legado_flutter/application/preferences/shared_preferences_runtime.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('loads the existing bookshelf keys and defaults', () async {
    SharedPreferences.setMockInitialValues({
      'bookGroupStyle': 1,
      'bookshelfLayout': 4,
      'bookshelfSort': 5,
      'showUnread': false,
      'showLastUpdateTime': true,
      'showWaitUpCount': true,
      'showBookshelfFastScroller': true,
      'onlyUpdateRead': true,
      'showBooknameLayout': 2,
      'bookshelfMargin': 42,
      'shelf_book_order': ['a', 'b'],
    });
    SharedPreferencesRuntime.resetForTest();

    const port = SharedPreferencesBookshelfConfigDialogPortAdapter();
    final config = await port.load();

    expect(config.bookGroupStyle, 1);
    expect(config.bookshelfLayout, 4);
    expect(config.bookshelfSort, 5);
    expect(config.showUnread, isFalse);
    expect(config.showLastUpdateTime, isTrue);
    expect(config.showWaitUpCount, isTrue);
    expect(config.showBookshelfFastScroller, isTrue);
    expect(config.onlyUpdateRead, isTrue);
    expect(config.showBookname, 2);
    expect(config.bookshelfMargin, 42);
    expect(config.bookOrder, ['a', 'b']);
  });

  test('saves dialog settings using legacy-compatible keys', () async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesRuntime.resetForTest();
    const port = SharedPreferencesBookshelfConfigDialogPortAdapter();

    await port.save(
      const BookshelfConfig(
        bookGroupStyle: 1,
        bookshelfLayout: 6,
        bookshelfSort: 5,
        showUnread: false,
        showLastUpdateTime: true,
        showWaitUpCount: true,
        showBookshelfFastScroller: true,
        onlyUpdateRead: true,
        showBookname: 2,
        bookshelfMargin: 60,
        bookOrder: ['book-1'],
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('bookGroupStyle'), 1);
    expect(prefs.getInt('bookshelfLayout'), 6);
    expect(prefs.getInt('bookshelfSort'), 5);
    expect(prefs.getInt('shelf_sort_mode'), 5);
    expect(prefs.getBool('showUnread'), isFalse);
    expect(prefs.getBool('showLastUpdateTime'), isTrue);
    expect(prefs.getBool('showWaitUpCount'), isTrue);
    expect(prefs.getBool('showBookshelfFastScroller'), isTrue);
    expect(prefs.getBool('onlyUpdateRead'), isTrue);
    expect(prefs.getInt('showBooknameLayout'), 2);
    expect(prefs.getInt('bookshelfMargin'), 60);
    // 手动书籍顺序由 BookshelfPrefs.saveBookOrder 独立维护。
    expect(prefs.getStringList('shelf_book_order'), isNull);
  });
}
