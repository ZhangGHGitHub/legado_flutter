import '../../domain/ports/code_edit_prefs_store.dart';
import '../../infrastructure/preferences/shared_preferences_code_edit_prefs_store.dart';

/// 代码编辑器偏好 — 对齐 Jingshiro [PreferKey] / [AppConfig] 编辑项。
abstract final class CodeEditPrefs {
  static const editTheme = 'editTheme';
  static const editThemeDark = 'editThemeDark';
  static const editTemeAuto = 'editTemeAuto';
  static const editFontScale = 'editFontScale';
  static const editAutoWrap = 'editAutoWrap';
  static const editAutoComplete = 'editAutoComplete';
  static const editNonPrintable = 'editNonPrintable';

  /// 编辑器会话日志（Flutter 侧；对齐菜单「日志」可读历史）。
  static const editSessionLog = 'editSessionLog';

  static const defaultTheme = 1; // Monokai
  static const defaultThemeDark = 1;
  static const defaultFontScale = 18;
  static const defaultAutoWrap = true;
  static const defaultAutoComplete = true;
  static const defaultThemeAuto = true;
  static const maxLogLines = 200;

  static Future<CodeEditSettings> load({CodeEditPrefsStore? store}) async {
    final p = await _resolve(store);
    return CodeEditSettings(
      themeIndex: p.getInt(editTheme) ?? defaultTheme,
      themeDarkIndex: p.getInt(editThemeDark) ?? defaultThemeDark,
      themeAuto: p.getBool(editTemeAuto) ?? defaultThemeAuto,
      fontScale: p.getInt(editFontScale) ?? defaultFontScale,
      autoWrap: p.getBool(editAutoWrap) ?? defaultAutoWrap,
      autoComplete: p.getBool(editAutoComplete) ?? defaultAutoComplete,
      nonPrintable: p.getInt(editNonPrintable) ?? 0,
    );
  }

  static Future<void> saveTheme(
    int index, {
    required bool dark,
    CodeEditPrefsStore? store,
  }) async {
    final p = await _resolve(store);
    await p.setInt(dark ? editThemeDark : editTheme, index);
  }

  static Future<void> saveThemeAuto(bool v, {CodeEditPrefsStore? store}) async {
    final p = await _resolve(store);
    await p.setBool(editTemeAuto, v);
  }

  static Future<void> saveFontScale(int v, {CodeEditPrefsStore? store}) async {
    final p = await _resolve(store);
    await p.setInt(editFontScale, v);
  }

  static Future<void> saveAutoWrap(bool v, {CodeEditPrefsStore? store}) async {
    final p = await _resolve(store);
    await p.setBool(editAutoWrap, v);
  }

  static Future<void> saveAutoComplete(
    bool v, {
    CodeEditPrefsStore? store,
  }) async {
    final p = await _resolve(store);
    await p.setBool(editAutoComplete, v);
  }

  static Future<void> saveNonPrintable(
    int v, {
    CodeEditPrefsStore? store,
  }) async {
    final p = await _resolve(store);
    await p.setInt(editNonPrintable, v);
  }

  static Future<List<String>> loadLog({CodeEditPrefsStore? store}) async {
    final p = await _resolve(store);
    return p.getStringList(editSessionLog) ?? const <String>[];
  }

  static Future<void> appendLog(
    String line, {
    CodeEditPrefsStore? store,
  }) async {
    final p = await _resolve(store);
    final list = List<String>.from(
      p.getStringList(editSessionLog) ?? const <String>[],
    );
    final stamp = DateTime.now().toIso8601String().substring(11, 19);
    list.add('[$stamp] $line');
    while (list.length > maxLogLines) {
      list.removeAt(0);
    }
    await p.setStringList(editSessionLog, list);
  }

  static Future<void> clearLog({CodeEditPrefsStore? store}) async {
    final p = await _resolve(store);
    await p.remove(editSessionLog);
  }

  static Future<CodeEditPrefsStore> _resolve(CodeEditPrefsStore? store) {
    return store == null
        ? SharedPreferencesCodeEditPrefsStore.load()
        : Future<CodeEditPrefsStore>.value(store);
  }
}

class CodeEditSettings {
  const CodeEditSettings({
    required this.themeIndex,
    required this.themeDarkIndex,
    required this.themeAuto,
    required this.fontScale,
    required this.autoWrap,
    required this.autoComplete,
    required this.nonPrintable,
  });

  final int themeIndex;
  final int themeDarkIndex;
  final bool themeAuto;
  final int fontScale;
  final bool autoWrap;
  final bool autoComplete;
  final int nonPrintable;

  /// 按系统明暗与 [themeAuto] 解析当前主题下标（对齐 ChangeThemeDialog）。
  int resolveThemeIndex({required bool systemDark}) {
    if (themeAuto && systemDark) return themeDarkIndex;
    return themeIndex;
  }
}
