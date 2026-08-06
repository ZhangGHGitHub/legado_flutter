import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../domain/ports/rss_source_import_port.dart';
import '../../domain/rss/rss_source.dart';
import 'rss_source_store_port.dart';
import 'rss_state.dart';

typedef RssStateListener = void Function(RssState state);

/// RSS 源管理的 application 状态控制器。
final class RssSourceController {
  RssSourceController({
    RssSourceImportPort? sourceImportPort,
    RssSourceStorePort? sourceStore,
  }) : _sourceImportPort =
           sourceImportPort ?? const UnavailableRssSourceImportPort(),
       _sourceStore = sourceStore ?? const UnavailableRssSourceStorePort();

  final RssSourceImportPort _sourceImportPort;
  final RssSourceStorePort _sourceStore;
  final Set<RssStateListener> _listeners = {};
  final List<RssSource> _sources = [];
  RssState _state = const RssState();

  RssState get state => _state;
  List<RssSource> get sources => _state.sources;

  void addListener(RssStateListener listener) => _listeners.add(listener);

  void removeListener(RssStateListener listener) => _listeners.remove(listener);

  Future<void> loadSources() async {
    _sources
      ..clear()
      ..addAll(await _sourceStore.load());
    _publish();
  }

  List<RssSource> enabledSources({String? searchKey}) {
    var list = _sources.where((source) => source.enabled).toList()
      ..sort(_compareOrder);
    final key = searchKey?.trim();
    if (key == null || key.isEmpty) return list;
    if (key.startsWith('group:')) {
      final group = key.substring(6);
      return list
          .where((source) => _matchGroup(source.sourceGroup, group))
          .toList();
    }
    final lower = key.toLowerCase();
    return list
        .where(
          (source) =>
              source.sourceName.toLowerCase().contains(lower) ||
              source.sourceGroup.toLowerCase().contains(lower),
        )
        .toList();
  }

  List<String> enabledGroups() => _groups(enabledOnly: true);

  List<String> allGroups() => _groups(enabledOnly: false);

  /// 对齐原版 GroupManageDialog：新建分组会把未分组源归入该组。
  Future<void> addGroup(String group) async {
    final normalized = group.trim();
    if (normalized.isEmpty) return;

    var changed = false;
    for (var i = 0; i < _sources.length; i++) {
      if (_sources[i].sourceGroup.trim().isEmpty) {
        _sources[i] = _sources[i].copyWith(sourceGroup: normalized);
        changed = true;
      }
    }
    if (changed) await _persist();
  }

  /// 对齐原版 upGroup：只改写包含旧组名的源，并规范化为逗号分隔。
  Future<void> renameGroup(String oldGroup, String newGroup) async {
    final oldName = oldGroup.trim();
    if (oldName.isEmpty) return;
    final newName = newGroup.trim();
    var changed = false;
    for (var i = 0; i < _sources.length; i++) {
      final groups = _splitGroups(_sources[i].sourceGroup);
      if (!groups.contains(oldName)) continue;
      groups.remove(oldName);
      if (newName.isNotEmpty) groups.add(newName);
      final sourceGroup = groups.join(',');
      if (sourceGroup == _sources[i].sourceGroup) continue;
      _sources[i] = _sources[i].copyWith(sourceGroup: sourceGroup);
      changed = true;
    }
    if (changed) await _persist();
  }

  Future<void> deleteGroup(String group) => renameGroup(group, '');

  List<RssSource> managedSources({String? searchKey, String filter = 'all'}) {
    var list = List<RssSource>.of(_sources)..sort(_compareOrder);
    switch (filter) {
      case 'enabled':
        list = list.where((source) => source.enabled).toList();
      case 'disabled':
        list = list.where((source) => !source.enabled).toList();
      case 'login':
        list = list
            .where(
              (source) =>
                  source.loginUrl != null && source.loginUrl!.trim().isNotEmpty,
            )
            .toList();
      case 'null_group':
        list = list
            .where((source) => source.sourceGroup.trim().isEmpty)
            .toList();
      default:
        if (filter.startsWith('group:')) {
          final group = filter.substring(6);
          list = list
              .where((source) => _matchGroup(source.sourceGroup, group))
              .toList();
        }
    }
    final key = searchKey?.trim();
    if (key == null || key.isEmpty) return list;
    final lower = key.toLowerCase();
    return list
        .where(
          (source) =>
              source.sourceName.toLowerCase().contains(lower) ||
              source.sourceUrl.toLowerCase().contains(lower) ||
              source.sourceGroup.toLowerCase().contains(lower),
        )
        .toList();
  }

  Future<void> setEnabled(RssSource source, bool enabled) =>
      upsertSource(source.copyWith(enabled: enabled));

  Future<void> setEnabledMany(Iterable<String> urls, bool enabled) async {
    final selected = urls.toSet();
    var changed = false;
    for (var i = 0; i < _sources.length; i++) {
      final source = _sources[i];
      if (selected.contains(source.sourceUrl) && source.enabled != enabled) {
        _sources[i] = source.copyWith(enabled: enabled);
        changed = true;
      }
    }
    if (changed) await _persist();
  }

  Future<void> deleteSources(Iterable<String> urls) async {
    final selected = urls.toSet();
    final before = _sources.length;
    _sources.removeWhere((source) => selected.contains(source.sourceUrl));
    if (_sources.length != before) await _persist();
  }

  Future<void> topSources(Iterable<String> urls) async {
    final selected = urls.toSet();
    var maxOrder = _maxOrder();
    for (var i = 0; i < _sources.length; i++) {
      final source = _sources[i];
      if (selected.contains(source.sourceUrl)) {
        maxOrder += 1;
        _sources[i] = source.copyWith(customOrder: maxOrder);
      }
    }
    await _persist();
  }

  Future<bool> importSourcesFromUrl(String url) async {
    try {
      final content = await _sourceImportPort.fetch(url);
      return content != null && await importSources(content);
    } catch (error) {
      debugPrint('RSS import URL failed: $error');
      return false;
    }
  }

  Future<void> upsertSource(RssSource source) async {
    _upsertInMemory(source);
    await _persist();
  }

  Future<bool> importSources(String jsonText) async {
    try {
      final imported = _parseSources(jsonText);
      if (imported.isEmpty) return false;
      for (final source in imported) {
        _upsertInMemory(source);
      }
      await _persist();
      return true;
    } catch (error) {
      debugPrint('RSS import failed: $error');
      return false;
    }
  }

  /// 对齐原版 DefaultData.importDefaultRssSources：仅移除旧 `legado`
  /// 分组默认源，再按 sourceUrl 覆盖写入打包 JSON 中的默认源。
  Future<bool> importDefaultSources(String jsonText) async {
    try {
      final imported = _parseSources(jsonText);
      if (imported.isEmpty) return false;
      _sources.removeWhere((source) => source.sourceGroup == 'legado');
      for (final source in imported) {
        _upsertInMemory(source);
      }
      await _persist();
      return true;
    } catch (error) {
      debugPrint('RSS default import failed: $error');
      return false;
    }
  }

  Future<void> topSource(RssSource source) async {
    await upsertSource(source.copyWith(customOrder: _maxOrder() + 1));
  }

  Future<void> disableSource(RssSource source) =>
      upsertSource(source.copyWith(enabled: false));

  Future<void> deleteSource(RssSource source) async {
    _sources.removeWhere((item) => item.sourceUrl == source.sourceUrl);
    await _persist();
  }

  static int _compareOrder(RssSource left, RssSource right) {
    final order = right.customOrder.compareTo(left.customOrder);
    if (order != 0) return order;
    return left.sourceName.compareTo(right.sourceName);
  }

  static bool _matchGroup(String sourceGroup, String target) {
    if (target.isEmpty) return sourceGroup.isEmpty;
    return _splitGroups(sourceGroup).contains(target);
  }

  List<String> _groups({required bool enabledOnly}) {
    final groups = <String>{};
    for (final source in _sources) {
      if (enabledOnly && !source.enabled) continue;
      groups.addAll(_splitGroups(source.sourceGroup));
    }
    return groups.toList()..sort();
  }

  static Set<String> _splitGroups(String sourceGroup) => sourceGroup
      .split(RegExp(r'[,;，；]'))
      .map((group) => group.trim())
      .where((group) => group.isNotEmpty)
      .toSet();

  int _maxOrder() => _sources.fold<int>(
    0,
    (previous, source) =>
        source.customOrder > previous ? source.customOrder : previous,
  );

  void _upsertInMemory(RssSource source) {
    final index = _sources.indexWhere(
      (item) => item.sourceUrl == source.sourceUrl,
    );
    if (index >= 0) {
      _sources[index] = source;
    } else {
      _sources.add(source);
    }
  }

  static List<RssSource> _parseSources(String jsonText) {
    final decoded = jsonDecode(jsonText.trim());
    final list = decoded is List
        ? decoded
        : decoded is Map && decoded['sources'] is List
        ? decoded['sources'] as List
        : <dynamic>[];
    return list
        .whereType<Map>()
        .map((item) => RssSource.fromJson(Map<String, dynamic>.from(item)))
        .where((source) => source.sourceUrl.trim().isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _persist() async {
    await _sourceStore.save(List<RssSource>.unmodifiable(_sources));
    _publish();
  }

  void _publish() {
    _state = RssState(sources: List<RssSource>.unmodifiable(_sources));
    for (final listener in List<RssStateListener>.of(_listeners)) {
      listener(_state);
    }
  }
}

final class UnavailableRssSourceImportPort implements RssSourceImportPort {
  const UnavailableRssSourceImportPort();

  @override
  Future<String?> fetch(String url) async => null;
}
