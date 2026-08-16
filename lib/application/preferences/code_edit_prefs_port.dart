/// 代码编辑器偏好与会话日志的应用层边界。
abstract interface class CodeEditPrefsPort {
  Future<CodeEditSettings> load();

  Future<void> saveTheme(int index, {required bool dark});

  Future<void> saveThemeAuto(bool value);

  Future<void> saveFontScale(int value);

  Future<void> saveAutoWrap(bool value);

  Future<void> saveAutoComplete(bool value);

  Future<List<String>> loadLog();

  Future<void> appendLog(String line);

  Future<void> clearLog();
}

/// 代码编辑器当前生效前的持久化设置。
final class CodeEditSettings {
  const CodeEditSettings({
    required this.themeIndex,
    required this.themeDarkIndex,
    required this.themeAuto,
    required this.fontScale,
    required this.autoWrap,
    required this.autoComplete,
  });

  final int themeIndex;
  final int themeDarkIndex;
  final bool themeAuto;
  final int fontScale;
  final bool autoWrap;
  final bool autoComplete;

  int resolveThemeIndex({required bool systemDark}) {
    if (themeAuto && systemDark) return themeDarkIndex;
    return themeIndex;
  }
}
