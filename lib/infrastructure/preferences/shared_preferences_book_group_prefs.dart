import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/ports/book_group_prefs.dart';

/// SharedPreferences adapter for the bookshelf group JSON document.
final class SharedPreferencesBookGroupPrefs implements BookGroupPrefsPort {
  const SharedPreferencesBookGroupPrefs(this._prefs);

  final SharedPreferences _prefs;

  static Future<SharedPreferencesBookGroupPrefs> load() async {
    return SharedPreferencesBookGroupPrefs(
      await SharedPreferences.getInstance(),
    );
  }

  @override
  Future<String?> read(String key) async => _prefs.getString(key);

  @override
  Future<bool> write(String key, String value) => _prefs.setString(key, value);
}
