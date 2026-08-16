import 'dart:convert';

import '../application/book/book_group_policy.dart';
import '../domain/book/book_group.dart';
import '../domain/ports/book_group_prefs.dart';

/// 书架分组持久化 — 对齐 Jingshiro `book_groups` 表（SharedPreferences JSON）
abstract final class BookGroupStore {
  static const _prefsKey = 'book_groups_v1';

  static List<BookGroup>? _cache;
  static BookGroupPrefsPort? _configuredPrefs;

  static void configurePrefsPort(BookGroupPrefsPort prefs) {
    _configuredPrefs = prefs;
    _cache = null;
  }

  static void resetPrefsPort() {
    _configuredPrefs = null;
    _cache = null;
  }

  static List<BookGroup> get cached {
    final c = _cache;
    if (c != null) return List.unmodifiable(c);
    return BookGroupPolicy.defaultSystemGroups();
  }

  static Future<List<BookGroup>> load() async {
    final prefs = _resolvePrefs();
    final raw = await prefs.read(_prefsKey);
    if (raw == null || raw.isEmpty) {
      final defaults = BookGroupPolicy.defaultSystemGroups();
      _cache = defaults;
      await _persist(defaults, prefs: prefs);
      return List.from(defaults);
    }
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => BookGroup.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      _ensureSystemGroups(list);
      list.sort((a, b) => a.order.compareTo(b.order));
      _cache = list;
      return List.from(list);
    } catch (_) {
      final defaults = BookGroupPolicy.defaultSystemGroups();
      _cache = defaults;
      return List.from(defaults);
    }
  }

  static void _ensureSystemGroups(List<BookGroup> list) {
    final ids = list.map((g) => g.groupId).toSet();
    for (final sys in BookGroupPolicy.defaultSystemGroups()) {
      if (!ids.contains(sys.groupId)) list.add(sys);
    }
  }

  static Future<void> _persist(
    List<BookGroup> list, {
    BookGroupPrefsPort? prefs,
  }) async {
    final storage = prefs ?? _resolvePrefs();
    await storage.write(
      _prefsKey,
      jsonEncode(list.map((g) => g.toJson()).toList()),
    );
    _cache = List.from(list);
  }

  static Future<void> saveAll(List<BookGroup> list) async {
    final sorted = List<BookGroup>.from(list)
      ..sort((a, b) => a.order.compareTo(b.order));
    await _persist(sorted);
  }

  static Future<void> update(BookGroup group) async {
    final list = await load();
    final i = list.indexWhere((g) => g.groupId == group.groupId);
    if (i >= 0) {
      list[i] = group;
    } else {
      list.add(group);
    }
    await saveAll(list);
  }

  static Future<void> updateMany(Iterable<BookGroup> groups) async {
    final list = await load();
    for (final g in groups) {
      final i = list.indexWhere((x) => x.groupId == g.groupId);
      if (i >= 0) {
        list[i] = g;
      } else {
        list.add(g);
      }
    }
    await saveAll(list);
  }

  static Future<void> delete(BookGroup group) async {
    final list = await load();
    list.removeWhere((g) => g.groupId == group.groupId);
    await saveAll(list);
  }

  /// 对齐 [BookGroupDao.getUnusedId]：正整数位掩码 1,2,4,...
  static Future<int> unusedId() async {
    final list = await load();
    var sum = 0;
    for (final g in list) {
      if (g.groupId > 0) sum |= g.groupId;
    }
    var id = 1;
    while ((id & sum) != 0) {
      id <<= 1;
      if (id <= 0 || id > (1 << 30)) break;
    }
    return id;
  }

  static Future<bool> canAddGroup() async {
    final list = await load();
    final custom = list.where((g) => g.groupId >= 0).length;
    return custom < 64;
  }

  static Future<int> maxOrder() async {
    final list = await load();
    var max = 0;
    for (final g in list) {
      if (g.groupId >= 0 && g.order > max) max = g.order;
    }
    return max;
  }

  /// 可选分组（自定义）— 对齐 `flowSelect` groupId >= 0
  static Future<List<BookGroup>> loadSelectGroups() async {
    final list = await load();
    return list.where((g) => g.groupId >= 0).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  /// 菜单可见分组 — 对齐 show=true 的系统+自定义
  static Future<List<BookGroup>> loadShownGroups() async {
    final list = await load();
    return list.where((g) => g.show).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  /// 把书架已有字符串分组名同步为自定义 BookGroup（若尚不存在）
  static Future<void> syncNamesFromBooks(Iterable<String> names) async {
    final list = await load();
    final existing = list.map((g) => g.groupName).toSet();
    var changed = false;
    for (final name in names) {
      final n = name.trim();
      if (n.isEmpty || existing.contains(n)) continue;
      if (list.where((g) => g.groupId >= 0).length >= 64) break;
      var sum = 0;
      for (final g in list) {
        if (g.groupId > 0) sum |= g.groupId;
      }
      var nid = 1;
      while ((nid & sum) != 0) {
        nid <<= 1;
      }
      var maxOrd = 0;
      for (final g in list) {
        if (g.groupId >= 0 && g.order > maxOrd) maxOrd = g.order;
      }
      list.add(
        BookGroup(groupId: nid, groupName: n, order: maxOrd + 1, show: true),
      );
      existing.add(n);
      changed = true;
    }
    if (changed) await saveAll(list);
  }

  static BookGroupPrefsPort _resolvePrefs() {
    final prefs = _configuredPrefs;
    if (prefs == null) {
      throw StateError('BookGroupStore 尚未配置 BookGroupPrefsPort');
    }
    return prefs;
  }
}
