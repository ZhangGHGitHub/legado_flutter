import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/services/app_paths.dart';
import 'package:legado_flutter/services/bookshelf_prefs.dart';
import 'package:legado_flutter/services/network_prefs.dart';
import 'package:legado_flutter/services/settings_backup.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('SettingsBackup collect and apply roundtrip', () async {
    SharedPreferences.setMockInitialValues({
      'legado_theme_mode': 'dark',
      'legado_color_preset': 'night',
      BookshelfPrefs.bookGroupStyleKey: 1,
      NetworkPrefs.enabledKey: true,
      NetworkPrefs.hostKey: '127.0.0.1',
      NetworkPrefs.portKey: 7890,
      AppDataPrefs.dataDirKey: 'D:/legado_data',
    });

    final collected = await SettingsBackup.collect();
    expect(collected['legado_theme_mode'], 'dark');
    expect(collected['legado_color_preset'], 'night');
    expect(collected[BookshelfPrefs.bookGroupStyleKey], 1);
    expect(collected[NetworkPrefs.enabledKey], isTrue);
    expect(collected[NetworkPrefs.hostKey], '127.0.0.1');
    expect(collected[NetworkPrefs.portKey], 7890);
    expect(collected[AppDataPrefs.dataDirKey], 'D:/legado_data');

    SharedPreferences.setMockInitialValues({});
    await SettingsBackup.apply(Map<String, dynamic>.from(collected));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('legado_theme_mode'), 'dark');
    expect(prefs.getInt(BookshelfPrefs.bookGroupStyleKey), 1);
    expect(prefs.getBool(NetworkPrefs.enabledKey), isTrue);
    expect(prefs.getString(NetworkPrefs.hostKey), '127.0.0.1');
    expect(prefs.getInt(NetworkPrefs.portKey), 7890);
    expect(prefs.getString(AppDataPrefs.dataDirKey), 'D:/legado_data');
  });
}
