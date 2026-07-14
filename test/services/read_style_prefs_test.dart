import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/models/read_style_config.dart';
import 'package:legado_flutter/services/read_style_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('shareLayout defaults true and persists', () async {
    expect(await ReadStylePrefs.loadShareLayout(), isTrue);
    await ReadStylePrefs.saveShareLayout(false);
    expect(await ReadStylePrefs.loadShareLayout(), isFalse);
  });

  test('themeName defaults paper and persists dark', () async {
    expect(await ReadStylePrefs.loadThemeName(), 'paper');
    await ReadStylePrefs.saveThemeName('dark');
    expect(await ReadStylePrefs.loadThemeName(), 'dark');
    await ReadStylePrefs.saveThemeName('not-a-theme');
    expect(await ReadStylePrefs.loadThemeName(), 'dark');
  });

  test('slot overrides roundtrip', () async {
    await ReadStylePrefs.upsertOverride(
      'paper',
      const ReadStyleSlotOverride(
        name: '纸感',
        background: Color(0xFFF5F0E8),
        text: Color(0xFF333333),
        accent: Colors.orange,
      ),
    );
    final all = await ReadStylePrefs.loadOverrides();
    expect(all['paper']?.name, '纸感');
    expect(all['paper']?.background, const Color(0xFFF5F0E8));
    await ReadStylePrefs.clearOverride('paper');
    expect((await ReadStylePrefs.loadOverrides()).containsKey('paper'), isFalse);
  });
}
