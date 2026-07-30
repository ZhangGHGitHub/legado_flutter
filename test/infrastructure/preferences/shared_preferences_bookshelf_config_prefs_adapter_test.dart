import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/preferences/shared_preferences_runtime.dart';
import 'package:legado_flutter/infrastructure/preferences/shared_preferences_bookshelf_config_prefs_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('reads the existing bookGroupStyle key and default', () async {
    SharedPreferences.setMockInitialValues({'bookGroupStyle': 1});
    SharedPreferencesRuntime.resetForTest();

    const adapter = SharedPreferencesBookshelfConfigPrefsAdapter();

    expect(await adapter.loadGroupStyle(), 1);
  });

  test('preserves the existing default when the key is absent', () async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesRuntime.resetForTest();

    const adapter = SharedPreferencesBookshelfConfigPrefsAdapter();

    expect(await adapter.loadGroupStyle(), 0);
  });
}
