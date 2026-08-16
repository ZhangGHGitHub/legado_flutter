import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/ports/book_progress_sync_store.dart';
import '../../application/preferences/shared_preferences_runtime.dart';

/// SharedPreferences adapter for the book-progress sync timestamp boundary.
final class SharedPreferencesBookProgressSyncStore
    implements BookProgressSyncStore {
  const SharedPreferencesBookProgressSyncStore(this._prefs);

  final SharedPreferences? _prefs;

  static Future<SharedPreferencesBookProgressSyncStore> load() async {
    return SharedPreferencesBookProgressSyncStore(
      await SharedPreferencesRuntime.getOrNull(),
    );
  }

  @override
  Future<int?> read(String key) async => _prefs?.getInt(key);

  @override
  Future<void> write(String key, int value) async {
    await _prefs?.setInt(key, value);
  }
}
