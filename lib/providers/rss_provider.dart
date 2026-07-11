import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/rss_source.dart';

const _rssSourcesKey = 'legado_rss_sources';

/// RSS 订阅源管理 — 本地持久化（UI 层；规则引擎后续接入）
class RssProvider extends ChangeNotifier {
  List<RssSource> _sources = [];

  List<RssSource> get sources => List.unmodifiable(_sources);

  Future<void> loadSources() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_rssSourcesKey);
    if (raw == null || raw.isEmpty) {
      _sources = [];
    } else {
      try {
        _sources = RssSource.listFromJsonString(raw);
      } catch (_) {
        _sources = [];
      }
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _rssSourcesKey,
      jsonEncode(_sources.map((s) => s.toJson()).toList()),
    );
    notifyListeners();
  }

  List<RssSource> enabledSources({String? searchKey}) {
    var list = _sources.where((s) => s.enabled).toList()
      ..sort((a, b) {
        final order = b.customOrder.compareTo(a.customOrder);
        if (order != 0) return order;
        return a.sourceName.compareTo(b.sourceName);
      });

    final key = searchKey?.trim();
    if (key == null || key.isEmpty) return list;

    if (key.startsWith('group:')) {
      final group = key.substring(6);
      return list.where((s) => _matchGroup(s.sourceGroup, group)).toList();
    }

    final lower = key.toLowerCase();
    return list
        .where(
          (s) =>
              s.sourceName.toLowerCase().contains(lower) ||
              s.sourceGroup.toLowerCase().contains(lower),
        )
        .toList();
  }

  bool _matchGroup(String sourceGroup, String target) {
    if (target.isEmpty) return sourceGroup.isEmpty;
    return sourceGroup.split(',').map((g) => g.trim()).contains(target);
  }

  List<String> enabledGroups() {
    final groups = <String>{};
    for (final s in _sources.where((s) => s.enabled)) {
      for (final g in s.sourceGroup.split(',')) {
        final t = g.trim();
        if (t.isNotEmpty) groups.add(t);
      }
    }
    final sorted = groups.toList()..sort();
    return sorted;
  }

  Future<void> upsertSource(RssSource source) async {
    final i = _sources.indexWhere((s) => s.sourceUrl == source.sourceUrl);
    if (i >= 0) {
      _sources[i] = source;
    } else {
      _sources.add(source);
    }
    await _persist();
  }

  Future<bool> importSources(String jsonText) async {
    try {
      final decoded = jsonDecode(jsonText.trim());
      final list = decoded is List
          ? decoded
          : decoded is Map && decoded['sources'] is List
              ? decoded['sources'] as List
              : <dynamic>[];
      if (list.isEmpty) return false;
      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        final source = RssSource.fromJson(item);
        if (source.sourceUrl.isEmpty) continue;
        await upsertSource(source);
      }
      return true;
    } catch (e) {
      debugPrint('RSS import failed: $e');
      return false;
    }
  }

  Future<void> topSource(RssSource source) async {
    final maxOrder = _sources.fold<int>(
      0,
      (prev, s) => s.customOrder > prev ? s.customOrder : prev,
    );
    await upsertSource(source.copyWith(customOrder: maxOrder + 1));
  }

  Future<void> disableSource(RssSource source) async {
    await upsertSource(source.copyWith(enabled: false));
  }

  Future<void> deleteSource(RssSource source) async {
    _sources.removeWhere((s) => s.sourceUrl == source.sourceUrl);
    await _persist();
  }
}
