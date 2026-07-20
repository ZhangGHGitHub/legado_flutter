import 'package:shared_preferences/shared_preferences.dart';

/// 书源分组名目录 — 与书源字段解耦。
///
/// Jingshiro 的 `addGroup` 会把全部「未分组」书源改成新组名，桌面端体验差：
/// 无未分组时像加不上；有未分组时又会批量改掉源分组。
/// 这里单独持久化分组名，添加分组不再改动任何书源。
abstract final class SourceGroupCatalog {
  static const _prefsKey = 'book_source_group_catalog_v1';

  static List<String> _names = [];
  static bool _loaded = false;

  static List<String> get names => List.unmodifiable(_names);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? const <String>[];
    _names = raw
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    _loaded = true;
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _names);
  }

  static Future<void> ensureLoaded() async {
    if (!_loaded) await load();
  }

  /// 合并书源里已有的分组名（导入/编辑后调用）
  static Future<void> mergeFromSources(Iterable<String> fromSources) async {
    await ensureLoaded();
    final set = _names.toSet();
    var changed = false;
    for (final raw in fromSources) {
      final g = raw.trim();
      if (g.isEmpty || set.contains(g)) continue;
      set.add(g);
      changed = true;
    }
    if (!changed) return;
    _names = set.toList()..sort();
    await _persist();
  }

  static Future<bool> add(String name) async {
    await ensureLoaded();
    final n = name.trim();
    if (n.isEmpty) return false;
    if (_names.contains(n)) return false;
    _names = [..._names, n]..sort();
    await _persist();
    return true;
  }

  static Future<void> rename(String oldName, String newName) async {
    await ensureLoaded();
    final o = oldName.trim();
    final n = newName.trim();
    if (o.isEmpty) return;
    _names.remove(o);
    if (n.isNotEmpty && !_names.contains(n)) {
      _names.add(n);
    }
    _names.sort();
    await _persist();
  }

  static Future<void> remove(String name) async {
    await ensureLoaded();
    final n = name.trim();
    if (n.isEmpty) return;
    _names.remove(n);
    await _persist();
  }
}
