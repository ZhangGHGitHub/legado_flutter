import '../../application/reader/read_style_prefs_port.dart';
import '../../models/read_style_config.dart';
import '../../models/theme_typography.dart';
import '../../services/read_style_prefs.dart' as service;

/// 保留既有阅读样式 SharedPreferences 键名的 adapter。
final class SharedPreferencesReadStylePrefsAdapter
    implements ReadStylePrefsPort {
  const SharedPreferencesReadStylePrefsAdapter();

  @override
  Future<bool> loadShareLayout() => service.ReadStylePrefs.loadShareLayout();

  @override
  Future<void> saveShareLayout(bool value) =>
      service.ReadStylePrefs.saveShareLayout(value);

  @override
  Future<String> loadThemeName() => service.ReadStylePrefs.loadThemeName();

  @override
  Future<void> saveThemeName(String themeName) =>
      service.ReadStylePrefs.saveThemeName(themeName);

  @override
  Future<Map<String, ReadStyleSlotOverride>> loadOverrides() =>
      service.ReadStylePrefs.loadOverrides();

  @override
  Future<void> saveOverrides(
    Map<String, ReadStyleSlotOverride> overrides,
  ) => service.ReadStylePrefs.saveOverrides(overrides);

  @override
  Future<void> upsertOverride(
    String themeName,
    ReadStyleSlotOverride override,
  ) => service.ReadStylePrefs.upsertOverride(themeName, override);

  @override
  Future<void> clearOverride(String themeName) =>
      service.ReadStylePrefs.clearOverride(themeName);

  @override
  Future<Map<String, ThemeTypography>> loadTypographyMap() =>
      service.ReadStylePrefs.loadTypographyMap();

  @override
  Future<ThemeTypography?> loadTypography(String themeName) =>
      service.ReadStylePrefs.loadTypography(themeName);

  @override
  Future<void> saveTypography(String themeName, ThemeTypography typography) =>
      service.ReadStylePrefs.saveTypography(themeName, typography);

  @override
  Future<void> clearTypography(String themeName) =>
      service.ReadStylePrefs.clearTypography(themeName);
}
