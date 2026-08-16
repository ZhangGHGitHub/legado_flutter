import 'package:shared_preferences/shared_preferences.dart';

import '../../application/preferences/shared_preferences_runtime.dart';
import '../../application/rss/rss_read_state_port.dart';

/// 使用 SharedPreferences 保存 RSS 源的已读文章链接。
final class SharedPreferencesRssReadStateAdapter implements RssReadStatePort {
  const SharedPreferencesRssReadStateAdapter(this._prefs);

  final SharedPreferences? _prefs;

  static Future<SharedPreferencesRssReadStateAdapter> load() async {
    return SharedPreferencesRssReadStateAdapter(
      await SharedPreferencesRuntime.getOrNull(),
    );
  }

  @override
  Future<Set<String>> read(String sourceUrl) async {
    final values = _prefs?.getStringList(_key(sourceUrl));
    return values == null ? <String>{} : values.toSet();
  }

  @override
  Future<void> write(String sourceUrl, Iterable<String> links) async {
    await _prefs?.setStringList(_key(sourceUrl), links.toList(growable: false));
  }

  static String _key(String sourceUrl) =>
      'rss_read_${Uri.encodeComponent(sourceUrl)}';
}
