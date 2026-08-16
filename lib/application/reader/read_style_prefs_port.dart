import '../../models/read_style_config.dart';
import '../../models/theme_typography.dart';

/// 阅读样式主题槽和共享布局的持久化端口。
abstract interface class ReadStylePrefsPort {
  Future<bool> loadShareLayout();

  Future<void> saveShareLayout(bool value);

  Future<String> loadThemeName();

  Future<void> saveThemeName(String themeName);

  Future<Map<String, ReadStyleSlotOverride>> loadOverrides();

  Future<void> saveOverrides(
    Map<String, ReadStyleSlotOverride> overrides,
  );

  Future<void> upsertOverride(
    String themeName,
    ReadStyleSlotOverride override,
  );

  Future<void> clearOverride(String themeName);

  Future<Map<String, ThemeTypography>> loadTypographyMap();

  Future<ThemeTypography?> loadTypography(String themeName);

  Future<void> saveTypography(String themeName, ThemeTypography typography);

  Future<void> clearTypography(String themeName);
}
