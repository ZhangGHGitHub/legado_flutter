import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/pages/reader/reader_settings.dart';
import 'package:legado_flutter/services/read_book_config_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('pageMode and typography round-trip like ReadBookConfig.save', () async {
    const s = ReaderSettings(
      pageMode: 'cover',
      fontSize: 22,
      lineHeight: 2.0,
      hideStatusBar: false,
      screenTimeout: ScreenTimeoutMode.fiveMinutes,
    );
    await ReadBookConfigPrefs.save(s);
    final loaded = await ReadBookConfigPrefs.load();
    expect(loaded.pageMode, 'cover');
    expect(loaded.fontSize, 22);
    expect(loaded.lineHeight, 2.0);
    expect(loaded.hideStatusBar, isFalse);
    expect(loaded.screenTimeout, ScreenTimeoutMode.fiveMinutes);
  });

  test('load merges onto base defaults when empty', () async {
    final loaded = await ReadBookConfigPrefs.load();
    expect(loaded.pageMode, 'slide');
    expect(loaded.fontSize, 18);
  });
}
