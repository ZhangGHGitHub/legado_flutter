import 'package:shared_preferences/shared_preferences.dart';

import '../../application/preferences/bookshelf_display_prefs_port.dart';
import '../../application/preferences/shared_preferences_runtime.dart';

final class SharedPreferencesBookshelfDisplayPrefs
    implements BookshelfDisplayPrefsPort {
  const SharedPreferencesBookshelfDisplayPrefs(this._prefs);

  final SharedPreferences? _prefs;

  static Future<SharedPreferencesBookshelfDisplayPrefs> create() async {
    return SharedPreferencesBookshelfDisplayPrefs(
      await SharedPreferencesRuntime.getOrNull(),
    );
  }

  @override
  Future<BookshelfDisplayPrefs> load() async {
    final prefs = _prefs;
    if (prefs == null) return const BookshelfDisplayPrefs();
    return BookshelfDisplayPrefs(
      showGrouped: prefs.getBool('shelf_show_grouped') ?? false,
      pinnedIds: (prefs.getStringList('shelf_pinned_ids') ?? const []).toSet(),
    );
  }

  @override
  Future<bool> saveGrouped(bool value) async =>
      _prefs?.setBool('shelf_show_grouped', value) ?? false;

  @override
  Future<bool> savePinned(Iterable<String> ids) async =>
      _prefs?.setStringList('shelf_pinned_ids', ids.toList(growable: false)) ??
      false;
}
