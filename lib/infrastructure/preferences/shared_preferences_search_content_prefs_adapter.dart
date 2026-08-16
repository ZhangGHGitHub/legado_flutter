import 'package:shared_preferences/shared_preferences.dart';

import '../../application/preferences/search_content_prefs_port.dart';
import '../../application/preferences/shared_preferences_runtime.dart';

/// 使用既有键名保存正文搜索设置的 SharedPreferences adapter。
final class SharedPreferencesSearchContentPrefsAdapter
    implements SearchContentPrefsPort {
  const SharedPreferencesSearchContentPrefsAdapter(this._prefs);

  static const enableReplaceKey = 'search_content_enable_replace';
  static const enableRegexKey = 'search_content_enable_regex';
  static const scopeKey = 'search_content_scope';

  final SharedPreferences? _prefs;

  static Future<SharedPreferencesSearchContentPrefsAdapter> create() async {
    return SharedPreferencesSearchContentPrefsAdapter(
      await SharedPreferencesRuntime.getOrNull(),
    );
  }

  @override
  Future<SearchContentPrefs> load() async {
    final prefs = _prefs;
    return SearchContentPrefs(
      enableReplace: prefs?.getBool(enableReplaceKey) ?? true,
      enableRegex: prefs?.getBool(enableRegexKey) ?? false,
      scope:
          prefs?.getString(scopeKey) ??
          SearchContentPrefs.scopeCurrentAndCached,
    );
  }

  @override
  Future<void> save(SearchContentPrefs value) async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setBool(enableReplaceKey, value.enableReplace);
    await prefs.setBool(enableRegexKey, value.enableRegex);
    await prefs.setString(scopeKey, value.scope);
  }
}
