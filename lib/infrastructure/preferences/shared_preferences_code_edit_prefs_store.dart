import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/ports/code_edit_prefs_store.dart';
import '../../application/preferences/shared_preferences_runtime.dart';

/// SharedPreferences adapter for the code editor preference boundary.
final class SharedPreferencesCodeEditPrefsStore implements CodeEditPrefsStore {
  const SharedPreferencesCodeEditPrefsStore(this._prefs);

  final SharedPreferences? _prefs;

  static Future<SharedPreferencesCodeEditPrefsStore> load() async {
    return SharedPreferencesCodeEditPrefsStore(
      await SharedPreferencesRuntime.getOrNull(),
    );
  }

  @override
  int? getInt(String key) => _prefs?.getInt(key);

  @override
  bool? getBool(String key) => _prefs?.getBool(key);

  @override
  List<String>? getStringList(String key) => _prefs?.getStringList(key);

  @override
  Future<bool> setInt(String key, int value) =>
      _prefs?.setInt(key, value) ?? Future<bool>.value(false);

  @override
  Future<bool> setBool(String key, bool value) =>
      _prefs?.setBool(key, value) ?? Future<bool>.value(false);

  @override
  Future<bool> setStringList(String key, List<String> value) =>
      _prefs?.setStringList(key, value) ?? Future<bool>.value(false);

  @override
  Future<bool> remove(String key) =>
      _prefs?.remove(key) ?? Future<bool>.value(false);
}
