import '../../application/bookshelf/bookshelf_config_dialog_port.dart';
import '../../services/bookshelf_prefs.dart' as service;

/// 复用 BookshelfPrefs 的既有迁移、键名、默认值和缓存语义。
final class SharedPreferencesBookshelfConfigDialogPortAdapter
    implements BookshelfConfigDialogPort {
  const SharedPreferencesBookshelfConfigDialogPortAdapter();

  @override
  Future<BookshelfConfig> load() => service.BookshelfPrefs.load();

  @override
  Future<void> save(BookshelfConfig config) =>
      service.BookshelfPrefs.save(config);
}
