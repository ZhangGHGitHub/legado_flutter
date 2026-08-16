import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/features/reader/reader_settings.dart';
import 'package:legado_flutter/infrastructure/reader/read_book_config_prefs_port_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('preserves global reader config storage and merge behavior', () async {
    const port = ReadBookConfigPrefsPortAdapter();
    const settings = ReaderSettings(fontSize: 23, pageMode: 'cover');

    await port.save(settings);
    final loaded = await port.load();

    expect(loaded.fontSize, 23);
    expect(loaded.pageMode, 'cover');
  });
}
