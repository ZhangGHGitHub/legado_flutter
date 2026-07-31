import '../../application/bookshelf/bookshelf_display_port.dart';
import '../../domain/book/book.dart' as domain;
import '../../services/bookshelf_prefs.dart' as service;

/// 书架展示端口的 SharedPreferences/BookshelfPrefs 适配器。
final class SharedPreferencesBookshelfDisplayPortAdapter
    implements BookshelfDisplayPort {
  const SharedPreferencesBookshelfDisplayPortAdapter();

  @override
  Future<BookshelfConfig> loadConfig() => service.BookshelfPrefs.load();

  @override
  Future<List<String>> loadBookOrder() =>
      service.BookshelfPrefs.loadBookOrder();

  @override
  List<domain.Book> sortBooks(
    List<domain.Book> books, {
    required int sortMode,
    required List<String> orderIds,
    Set<String> pinnedIds = const {},
  }) => service.BookshelfPrefs.sortBooks(
    books,
    sortMode: sortMode,
    orderIds: orderIds,
    pinnedIds: pinnedIds,
  );
}
