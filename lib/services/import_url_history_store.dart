import 'package:shared_preferences/shared_preferences.dart';

/// 网络导入书源 URL 历史（最多 20 条）
abstract final class ImportUrlHistoryStore {
  static const _key = 'book_source_import_url_history_v1';
  static const maxEntries = 20;

  static Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<void> add(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = await load();
    list.remove(trimmed);
    list.insert(0, trimmed);
    if (list.length > maxEntries) {
      list.removeRange(maxEntries, list.length);
    }
    await prefs.setStringList(_key, list);
  }

  static Future<void> remove(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await load()..remove(url);
    await prefs.setStringList(_key, list);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
