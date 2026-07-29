import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/ports/rss_source_import_port.dart';
import 'package:legado_flutter/domain/rss/rss_source.dart';

const _rssSourcesKey = 'legado_rss_sources';

/// RSS 订阅源管理 — 本地持久化（UI 层；规则引擎后续接入）
class RssProvider extends ChangeNotifier {
  RssProvider({RssSourceImportPort? sourceImportPort})
    : _sourceImportPort =
          sourceImportPort ?? const _UnavailableRssSourceImportPort();

  final RssSourceImportPort _sourceImportPort;
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

  /// 全部源的分组名（含禁用），供管理页筛选
  List<String> allGroups() {
    final groups = <String>{};
    for (final s in _sources) {
      for (final g in s.sourceGroup.split(',')) {
        final t = g.trim();
        if (t.isNotEmpty) groups.add(t);
      }
    }
    final sorted = groups.toList()..sort();
    return sorted;
  }

  /// 管理页列表过滤：搜索 + 分组/启用态
  List<RssSource> managedSources({String? searchKey, String filter = 'all'}) {
    var list = List<RssSource>.from(_sources)
      ..sort((a, b) {
        final order = b.customOrder.compareTo(a.customOrder);
        if (order != 0) return order;
        return a.sourceName.compareTo(b.sourceName);
      });

    switch (filter) {
      case 'enabled':
        list = list.where((s) => s.enabled).toList();
      case 'disabled':
        list = list.where((s) => !s.enabled).toList();
      case 'login':
        list = list
            .where((s) => s.loginUrl != null && s.loginUrl!.trim().isNotEmpty)
            .toList();
      case 'null_group':
        list = list.where((s) => s.sourceGroup.trim().isEmpty).toList();
      default:
        if (filter.startsWith('group:')) {
          final g = filter.substring(6);
          list = list.where((s) => _matchGroup(s.sourceGroup, g)).toList();
        }
    }

    final key = searchKey?.trim();
    if (key == null || key.isEmpty) return list;
    final lower = key.toLowerCase();
    return list
        .where(
          (s) =>
              s.sourceName.toLowerCase().contains(lower) ||
              s.sourceUrl.toLowerCase().contains(lower) ||
              s.sourceGroup.toLowerCase().contains(lower),
        )
        .toList();
  }

  Future<void> setEnabled(RssSource source, bool enabled) async {
    await upsertSource(source.copyWith(enabled: enabled));
  }

  Future<void> setEnabledMany(Iterable<String> urls, bool enabled) async {
    final set = urls.toSet();
    var changed = false;
    for (var i = 0; i < _sources.length; i++) {
      final s = _sources[i];
      if (set.contains(s.sourceUrl) && s.enabled != enabled) {
        _sources[i] = s.copyWith(enabled: enabled);
        changed = true;
      }
    }
    if (changed) await _persist();
  }

  Future<void> deleteSources(Iterable<String> urls) async {
    final set = urls.toSet();
    final before = _sources.length;
    _sources.removeWhere((s) => set.contains(s.sourceUrl));
    if (_sources.length != before) await _persist();
  }

  Future<void> topSources(Iterable<String> urls) async {
    final set = urls.toSet();
    var maxOrder = _sources.fold<int>(
      0,
      (prev, s) => s.customOrder > prev ? s.customOrder : prev,
    );
    for (var i = 0; i < _sources.length; i++) {
      final s = _sources[i];
      if (set.contains(s.sourceUrl)) {
        maxOrder += 1;
        _sources[i] = s.copyWith(customOrder: maxOrder);
      }
    }
    await _persist();
  }

  Future<bool> importSourcesFromUrl(String url) async {
    try {
      final content = await _sourceImportPort.fetch(url);
      return content != null && await importSources(content);
    } catch (e) {
      debugPrint('RSS import URL failed: $e');
      return false;
    }
  }

  Future<void> upsertSource(RssSource source) async {
    _upsertInMemory(source);
    await _persist();
  }

  void _upsertInMemory(RssSource source) {
    final i = _sources.indexWhere((s) => s.sourceUrl == source.sourceUrl);
    if (i >= 0) {
      _sources[i] = source;
    } else {
      _sources.add(source);
    }
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
      final imported = <RssSource>[];
      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        final source = RssSource.fromJson(item);
        if (source.sourceUrl.trim().isEmpty) continue;
        imported.add(source);
      }
      if (imported.isEmpty) return false;
      for (final source in imported) {
        _upsertInMemory(source);
      }
      await _persist();
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

class _UnavailableRssSourceImportPort implements RssSourceImportPort {
  const _UnavailableRssSourceImportPort();

  @override
  Future<String?> fetch(String url) async => null;
}
