import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/infrastructure/preferences/shared_preferences_read_style_prefs_adapter.dart';
import 'package:legado_flutter/models/read_style_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('preserves read style keys and validation through the adapter', () async {
    SharedPreferences.setMockInitialValues({});
    const adapter = SharedPreferencesReadStylePrefsAdapter();

    expect(await adapter.loadShareLayout(), isTrue);
    expect(await adapter.loadThemeName(), 'paper');

    await adapter.saveShareLayout(false);
    await adapter.saveThemeName('dark');
    await adapter.saveThemeName('unknown');
    await adapter.upsertOverride(
      'dark',
      const ReadStyleSlotOverride(
        name: '夜间',
        background: Color(0xFF222222),
        text: Colors.white,
      ),
    );

    expect(await adapter.loadShareLayout(), isFalse);
    expect(await adapter.loadThemeName(), 'dark');
    expect((await adapter.loadOverrides())['dark']?.name, '夜间');
  });
}
