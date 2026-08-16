import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/preferences/search_content_prefs_port.dart';
import 'package:legado_flutter/infrastructure/preferences/shared_preferences_search_content_prefs_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('preserves search content keys, defaults, and save behavior', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final adapter = SharedPreferencesSearchContentPrefsAdapter(prefs);

    expect(await adapter.load(), isA<SearchContentPrefs>());
    final defaults = await adapter.load();
    expect(defaults.enableReplace, isTrue);
    expect(defaults.enableRegex, isFalse);
    expect(defaults.scope, SearchContentPrefs.scopeCurrentAndCached);

    const saved = SearchContentPrefs(
      enableReplace: false,
      enableRegex: true,
      scope: SearchContentPrefs.scopeCurrent,
    );
    await adapter.save(saved);

    expect(prefs.getBool('search_content_enable_replace'), isFalse);
    expect(prefs.getBool('search_content_enable_regex'), isTrue);
    expect(prefs.getString('search_content_scope'), 'current');
    expect((await adapter.load()).scope, SearchContentPrefs.scopeCurrent);
  });
}
