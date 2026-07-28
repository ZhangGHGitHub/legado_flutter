import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/code_edit_prefs_store.dart';
import 'package:legado_flutter/infrastructure/preferences/shared_preferences_code_edit_prefs_store.dart';
import 'package:legado_flutter/services/code_edit_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('loads defaults through the injected store', () async {
    final store = _MemoryCodeEditPrefsStore();

    final settings = await CodeEditPrefs.load(store: store);

    expect(settings.themeIndex, CodeEditPrefs.defaultTheme);
    expect(settings.themeDarkIndex, CodeEditPrefs.defaultThemeDark);
    expect(settings.themeAuto, CodeEditPrefs.defaultThemeAuto);
    expect(settings.fontScale, CodeEditPrefs.defaultFontScale);
    expect(settings.autoWrap, CodeEditPrefs.defaultAutoWrap);
    expect(settings.autoComplete, CodeEditPrefs.defaultAutoComplete);
    expect(settings.nonPrintable, 0);
  });

  test('loads and saves all preference value types through the port', () async {
    final store = _MemoryCodeEditPrefsStore({
      CodeEditPrefs.editTheme: 3,
      CodeEditPrefs.editThemeDark: 4,
      CodeEditPrefs.editTemeAuto: false,
      CodeEditPrefs.editFontScale: 21,
      CodeEditPrefs.editAutoWrap: false,
      CodeEditPrefs.editAutoComplete: false,
      CodeEditPrefs.editNonPrintable: 2,
    });

    final settings = await CodeEditPrefs.load(store: store);
    expect(settings.themeIndex, 3);
    expect(settings.themeDarkIndex, 4);
    expect(settings.themeAuto, isFalse);
    expect(settings.fontScale, 21);
    expect(settings.autoWrap, isFalse);
    expect(settings.autoComplete, isFalse);
    expect(settings.nonPrintable, 2);

    await CodeEditPrefs.saveTheme(5, dark: false, store: store);
    await CodeEditPrefs.saveTheme(6, dark: true, store: store);
    await CodeEditPrefs.saveThemeAuto(true, store: store);
    await CodeEditPrefs.saveFontScale(19, store: store);
    await CodeEditPrefs.saveAutoWrap(true, store: store);
    await CodeEditPrefs.saveAutoComplete(true, store: store);
    await CodeEditPrefs.saveNonPrintable(1, store: store);

    expect(store.ints, containsPair(CodeEditPrefs.editTheme, 5));
    expect(store.ints, containsPair(CodeEditPrefs.editThemeDark, 6));
    expect(store.bools, containsPair(CodeEditPrefs.editTemeAuto, true));
    expect(store.ints, containsPair(CodeEditPrefs.editFontScale, 19));
    expect(store.bools, containsPair(CodeEditPrefs.editAutoWrap, true));
    expect(store.bools, containsPair(CodeEditPrefs.editAutoComplete, true));
    expect(store.ints, containsPair(CodeEditPrefs.editNonPrintable, 1));
  });

  test('session logs append, cap, load, and clear through the port', () async {
    final store = _MemoryCodeEditPrefsStore();

    await CodeEditPrefs.appendLog('first', store: store);
    expect(await CodeEditPrefs.loadLog(store: store), hasLength(1));
    expect(
      (await CodeEditPrefs.loadLog(store: store)).single,
      endsWith(' first'),
    );

    for (var i = 0; i < CodeEditPrefs.maxLogLines + 1; i++) {
      await CodeEditPrefs.appendLog('line $i', store: store);
    }
    final logs = await CodeEditPrefs.loadLog(store: store);
    expect(logs, hasLength(CodeEditPrefs.maxLogLines));
    expect(logs.first, endsWith('line 1'));
    expect(logs.last, endsWith('line ${CodeEditPrefs.maxLogLines}'));

    await CodeEditPrefs.clearLog(store: store);
    expect(await CodeEditPrefs.loadLog(store: store), isEmpty);
  });

  test('SharedPreferences adapter preserves the established keys', () async {
    SharedPreferences.setMockInitialValues({
      CodeEditPrefs.editTheme: 7,
      CodeEditPrefs.editSessionLog: <String>['[12:00:00] saved'],
    });
    final prefs = await SharedPreferences.getInstance();
    final store = SharedPreferencesCodeEditPrefsStore(prefs);

    expect(store.getInt(CodeEditPrefs.editTheme), 7);
    expect(store.getStringList(CodeEditPrefs.editSessionLog), [
      '[12:00:00] saved',
    ]);
    await store.setBool(CodeEditPrefs.editAutoWrap, false);
    await store.remove(CodeEditPrefs.editSessionLog);

    expect(prefs.getBool(CodeEditPrefs.editAutoWrap), isFalse);
    expect(prefs.getStringList(CodeEditPrefs.editSessionLog), isNull);
  });
}

final class _MemoryCodeEditPrefsStore implements CodeEditPrefsStore {
  _MemoryCodeEditPrefsStore([Map<String, Object?> initial = const {}]) {
    for (final entry in initial.entries) {
      if (entry.value is int) ints[entry.key] = entry.value! as int;
      if (entry.value is bool) bools[entry.key] = entry.value! as bool;
      if (entry.value is List<String>) {
        lists[entry.key] = List<String>.from(entry.value! as List<String>);
      }
    }
  }

  final ints = <String, int>{};
  final bools = <String, bool>{};
  final lists = <String, List<String>>{};

  @override
  int? getInt(String key) => ints[key];

  @override
  bool? getBool(String key) => bools[key];

  @override
  List<String>? getStringList(String key) => lists[key];

  @override
  Future<bool> setInt(String key, int value) async {
    ints[key] = value;
    return true;
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    bools[key] = value;
    return true;
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    lists[key] = List<String>.from(value);
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    ints.remove(key);
    bools.remove(key);
    lists.remove(key);
    return true;
  }
}
