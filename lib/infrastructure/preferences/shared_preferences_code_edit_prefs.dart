import '../../application/preferences/code_edit_prefs_port.dart';
import '../../domain/ports/code_edit_prefs_store.dart';
import '../../services/code_edit_prefs.dart' as service;
import 'shared_preferences_code_edit_prefs_store.dart';

/// 使用现有 SharedPreferences 键名保存代码编辑器偏好。
final class SharedPreferencesCodeEditPrefs implements CodeEditPrefsPort {
  const SharedPreferencesCodeEditPrefs(this._store);

  final CodeEditPrefsStore _store;

  static Future<SharedPreferencesCodeEditPrefs> loadFromRuntime() async {
    return SharedPreferencesCodeEditPrefs(
      await SharedPreferencesCodeEditPrefsStore.load(),
    );
  }

  @override
  Future<CodeEditSettings> load() async {
    final settings = await service.CodeEditPrefs.load(store: _store);
    return CodeEditSettings(
      themeIndex: settings.themeIndex,
      themeDarkIndex: settings.themeDarkIndex,
      themeAuto: settings.themeAuto,
      fontScale: settings.fontScale,
      autoWrap: settings.autoWrap,
      autoComplete: settings.autoComplete,
    );
  }

  @override
  Future<void> saveTheme(int index, {required bool dark}) async {
    await service.CodeEditPrefs.saveTheme(index, dark: dark, store: _store);
  }

  @override
  Future<void> saveThemeAuto(bool value) async {
    await service.CodeEditPrefs.saveThemeAuto(value, store: _store);
  }

  @override
  Future<void> saveFontScale(int value) async {
    await service.CodeEditPrefs.saveFontScale(value, store: _store);
  }

  @override
  Future<void> saveAutoWrap(bool value) async {
    await service.CodeEditPrefs.saveAutoWrap(value, store: _store);
  }

  @override
  Future<void> saveAutoComplete(bool value) async {
    await service.CodeEditPrefs.saveAutoComplete(value, store: _store);
  }

  @override
  Future<List<String>> loadLog() =>
      service.CodeEditPrefs.loadLog(store: _store);

  @override
  Future<void> appendLog(String line) async {
    await service.CodeEditPrefs.appendLog(line, store: _store);
  }

  @override
  Future<void> clearLog() async {
    await service.CodeEditPrefs.clearLog(store: _store);
  }
}
