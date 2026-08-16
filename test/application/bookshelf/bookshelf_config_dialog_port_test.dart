import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_config_dialog_port.dart';

final class _MemoryBookshelfConfigDialogPort
    implements BookshelfConfigDialogPort {
  _MemoryBookshelfConfigDialogPort(this._config);

  BookshelfConfig _config;

  @override
  Future<BookshelfConfig> load() async => _config;

  @override
  Future<void> save(BookshelfConfig config) async {
    _config = config;
  }
}

void main() {
  test(
    'supports loading and saving the complete bookshelf configuration',
    () async {
      const initial = BookshelfConfig(
        bookGroupStyle: 1,
        bookshelfLayout: 3,
        bookshelfSort: 5,
        showUnread: false,
        showLastUpdateTime: true,
        showWaitUpCount: true,
        showBookshelfFastScroller: true,
        onlyUpdateRead: true,
        showBookname: 2,
        bookshelfMargin: 36,
        bookOrder: ['book-2', 'book-1'],
      );
      final port = _MemoryBookshelfConfigDialogPort(initial);

      expect(await port.load(), same(initial));
      await port.save(const BookshelfConfig(bookshelfLayout: 6));

      final saved = await port.load();
      expect(saved.bookshelfLayout, 6);
      expect(saved.bookGroupStyle, 0);
      expect(saved.bookshelfMargin, 12);
    },
  );
}
