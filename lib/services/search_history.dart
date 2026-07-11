import 'package:shared_preferences/shared_preferences.dart';

/// 联合搜索历史（最多 20 条）
abstract final class SearchHistory {
  static const _key = 'legado_search_history';
  static const maxItems = 20;

  static Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<void> add(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = await load();
    list.remove(trimmed);
    list.insert(0, trimmed);
    if (list.length > maxItems) {
      list.removeRange(maxItems, list.length);
    }
    await prefs.setStringList(_key, list);
  }

  static Future<void> remove(String keyword) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await load()..remove(keyword);
    await prefs.setStringList(_key, list);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
