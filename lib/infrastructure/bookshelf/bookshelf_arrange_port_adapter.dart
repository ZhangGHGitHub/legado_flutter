import '../../application/bookshelf/bookshelf_arrange_port.dart';
import '../../services/bookshelf_arrange_prefs.dart' as arrange_service;
import '../../services/bookshelf_prefs.dart';

/// 书架整理端口的现有 SharedPreferences/BookshelfPrefs 适配器。
final class SharedPreferencesBookshelfArrangePortAdapter
    implements BookshelfArrangePort {
  const SharedPreferencesBookshelfArrangePortAdapter();

  @override
  Future<bool> loadOpenBookInfoByTitle() =>
      const arrange_service.SharedPreferencesBookshelfArrangePrefs()
          .loadOpenBookInfoByTitle();

  @override
  Future<void> saveOpenBookInfoByTitle(bool value) =>
      const arrange_service.SharedPreferencesBookshelfArrangePrefs()
          .saveOpenBookInfoByTitle(value);

  @override
  Future<int> loadSortMode() => BookshelfPrefs.loadSortMode();

  @override
  Future<List<String>> loadBookOrder() => BookshelfPrefs.loadBookOrder();

  @override
  Future<void> saveBookOrder(List<String> ids) =>
      BookshelfPrefs.saveBookOrder(ids);

  @override
  Future<void> saveSortMode(int mode) => BookshelfPrefs.saveSortMode(mode);
}
