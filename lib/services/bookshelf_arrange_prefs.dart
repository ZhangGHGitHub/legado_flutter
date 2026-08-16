import 'package:shared_preferences/shared_preferences.dart';

/// Preferences used by the bookshelf arrange page.
abstract interface class BookshelfArrangePrefsPort {
  static const openBookInfoByTitleKey = 'openBookInfoByClickTitle';

  Future<bool> loadOpenBookInfoByTitle();

  Future<void> saveOpenBookInfoByTitle(bool value);
}

/// SharedPreferences adapter for the bookshelf arrange page.
class SharedPreferencesBookshelfArrangePrefs
    implements BookshelfArrangePrefsPort {
  const SharedPreferencesBookshelfArrangePrefs();

  @override
  Future<bool> loadOpenBookInfoByTitle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(BookshelfArrangePrefsPort.openBookInfoByTitleKey) ??
        false;
  }

  @override
  Future<void> saveOpenBookInfoByTitle(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      BookshelfArrangePrefsPort.openBookInfoByTitleKey,
      value,
    );
  }
}
