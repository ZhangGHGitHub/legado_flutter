import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/services/bookshelf_prefs.dart';
import 'package:legado_flutter/services/settings_backup.dart';

void main() {
  test('collect reads supported preference types through the port', () async {
    final store = MemorySettingsStore({
      'legado_theme_mode': 'dark',
      BookshelfPrefs.bookshelfLayoutKey: 2,
      BookshelfPrefs.showUnreadKey: true,
      'unrelated_key': 'ignored',
    });

    final result = await SettingsBackup.collect(store: store);

    expect(result['legado_theme_mode'], 'dark');
    expect(result[BookshelfPrefs.bookshelfLayoutKey], 2);
    expect(result[BookshelfPrefs.showUnreadKey], isTrue);
    expect(result, isNot(contains('unrelated_key')));
  });

  test('apply writes supported preference types through the port', () async {
    final store = MemorySettingsStore();

    await SettingsBackup.apply({
      'legado_theme_mode': 'light',
      BookshelfPrefs.bookshelfLayoutKey: 3,
      BookshelfPrefs.showUnreadKey: false,
      'unsupported_value': ['ignored'],
    }, store: store);

    expect(store.values['legado_theme_mode'], 'light');
    expect(store.values[BookshelfPrefs.bookshelfLayoutKey], 3);
    expect(store.values[BookshelfPrefs.showUnreadKey], isFalse);
    expect(store.values, isNot(contains('unsupported_value')));
  });
}

final class MemorySettingsStore implements SettingsStore {
  MemorySettingsStore([Map<String, Object?>? initial]) : values = {...?initial};

  final Map<String, Object?> values;

  @override
  bool containsKey(String key) => values.containsKey(key);

  @override
  int? getInt(String key) => values[key] as int?;

  @override
  bool? getBool(String key) => values[key] as bool?;

  @override
  String? getString(String key) => values[key] as String?;

  @override
  Future<bool> setInt(String key, int value) async {
    values[key] = value;
    return true;
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    values[key] = value;
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    values[key] = value;
    return true;
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    values[key] = value;
    return true;
  }
}
