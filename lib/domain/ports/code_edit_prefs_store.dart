/// Persistence boundary for code editor preferences and session logs.
abstract interface class CodeEditPrefsStore {
  int? getInt(String key);

  bool? getBool(String key);

  List<String>? getStringList(String key);

  Future<bool> setInt(String key, int value);

  Future<bool> setBool(String key, bool value);

  Future<bool> setStringList(String key, List<String> value);

  Future<bool> remove(String key);
}
