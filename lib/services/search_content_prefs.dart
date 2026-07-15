import 'package:shared_preferences/shared_preferences.dart';

/// 全文搜索选项（对齐 legado `menu_enable_replace` / `menu_enable_regex`）
class SearchContentPrefs {
  static const _kEnableReplace = 'search_content_enable_replace';
  static const _kEnableRegex = 'search_content_enable_regex';

  bool enableReplace;
  bool enableRegex;

  SearchContentPrefs({
    this.enableReplace = true,
    this.enableRegex = false,
  });

  static Future<SearchContentPrefs> load() async {
    final p = await SharedPreferences.getInstance();
    return SearchContentPrefs(
      enableReplace: p.getBool(_kEnableReplace) ?? true,
      enableRegex: p.getBool(_kEnableRegex) ?? false,
    );
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kEnableReplace, enableReplace);
    await p.setBool(_kEnableRegex, enableRegex);
  }
}
