import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/rule_sub.dart';

/// 规则订阅持久化 — SharedPreferences JSON，对齐 Jingshiro `ruleSubs` 表
class RuleSubPrefs {
  static const _kSubs = 'rule_subs_v1';

  static List<RuleSub>? _cache;

  static List<RuleSub> get cached => List.unmodifiable(_cache ?? const []);

  static Future<List<RuleSub>> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kSubs);
    if (raw == null || raw.isEmpty) {
      _cache = [];
      return [];
    }
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => RuleSub.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList()
        ..sort((a, b) => a.customOrder.compareTo(b.customOrder));
      _cache = list;
      return List<RuleSub>.from(list);
    } catch (_) {
      _cache = [];
      return [];
    }
  }

  static Future<void> save(List<RuleSub> subs) async {
    final sorted = List<RuleSub>.from(subs)
      ..sort((a, b) => a.customOrder.compareTo(b.customOrder));
    _cache = sorted;
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _kSubs,
      jsonEncode(sorted.map((e) => e.toJson()).toList()),
    );
  }

  static Future<RuleSub?> findByUrl(String url) async {
    final all = await load();
    for (final s in all) {
      if (s.url == url) return s;
    }
    return null;
  }

  static Future<int> maxOrder() async {
    final all = await load();
    if (all.isEmpty) return 0;
    return all.map((e) => e.customOrder).reduce((a, b) => a > b ? a : b);
  }

  static Future<void> upsert(RuleSub sub) async {
    final all = await load();
    final i = all.indexWhere((e) => e.id == sub.id);
    if (i >= 0) {
      all[i] = sub;
    } else {
      all.add(sub);
    }
    await save(all);
  }

  static Future<void> delete(RuleSub sub) async {
    final all = await load();
    all.removeWhere((e) => e.id == sub.id);
    await save(all);
  }

  static Future<void> updateAll(List<RuleSub> changed) async {
    if (changed.isEmpty) return;
    final all = await load();
    final byId = {for (final s in changed) s.id: s};
    for (var i = 0; i < all.length; i++) {
      final next = byId[all[i].id];
      if (next != null) all[i] = next;
    }
    await save(all);
  }
}
