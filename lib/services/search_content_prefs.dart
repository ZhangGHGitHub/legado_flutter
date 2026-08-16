import 'package:shared_preferences/shared_preferences.dart';

/// 全文搜索选项（对齐 legado `menu_enable_replace` / `menu_enable_regex`）。
class SearchContentPrefs {
  static const _kEnableReplace = 'search_content_enable_replace';
  static const _kEnableRegex = 'search_content_enable_regex';
  static const _kScope = 'search_content_scope';

  static const scopeCurrent = 'current';
  static const scopeCurrentAndCached = 'current_and_cached';
  static const scopeCurrentAndNetwork = 'current_and_network';

  bool enableReplace;
  bool enableRegex;
  String scope;

  SearchContentPrefs({
    this.enableReplace = true,
    this.enableRegex = false,
    this.scope = scopeCurrentAndCached,
  });

  static Future<SearchContentPrefs> load() async {
    final p = await SharedPreferences.getInstance();
    return SearchContentPrefs(
      enableReplace: p.getBool(_kEnableReplace) ?? true,
      enableRegex: p.getBool(_kEnableRegex) ?? false,
      scope: p.getString(_kScope) ?? scopeCurrentAndCached,
    );
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kEnableReplace, enableReplace);
    await p.setBool(_kEnableRegex, enableRegex);
    await p.setString(_kScope, scope);
  }
}
