import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/services/search_content_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('search scope persists with replace and regex options', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = SearchContentPrefs(
      enableReplace: false,
      enableRegex: true,
      scope: SearchContentPrefs.scopeCurrent,
    );
    await prefs.save();

    final loaded = await SearchContentPrefs.load();
    expect(loaded.enableReplace, isFalse);
    expect(loaded.enableRegex, isTrue);
    expect(loaded.scope, SearchContentPrefs.scopeCurrent);
  });

  test('supports the whole-book network scope', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = SearchContentPrefs(
      scope: SearchContentPrefs.scopeCurrentAndNetwork,
    );
    await prefs.save();

    final loaded = await SearchContentPrefs.load();
    expect(loaded.scope, SearchContentPrefs.scopeCurrentAndNetwork);
  });
}
