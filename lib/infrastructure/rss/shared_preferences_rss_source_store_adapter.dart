import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../application/rss/rss_source_store_port.dart';
import '../../domain/rss/rss_source.dart';

/// 使用既有键名保存 RSS 订阅源列表的 SharedPreferences adapter。
final class SharedPreferencesRssSourceStoreAdapter
    implements RssSourceStorePort {
  const SharedPreferencesRssSourceStoreAdapter([this._prefs]);

  static const sourcesKey = 'legado_rss_sources';

  final SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  @override
  Future<List<RssSource>> load() async {
    final raw = (await _getPrefs()).getString(sourcesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return RssSource.listFromJsonString(raw);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> save(List<RssSource> sources) async {
    await (await _getPrefs()).setString(
      sourcesKey,
      jsonEncode(sources.map((source) => source.toJson()).toList()),
    );
  }
}
