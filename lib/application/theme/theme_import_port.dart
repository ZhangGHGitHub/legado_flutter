import '../../domain/ports/public_text_fetch_port.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_config_model.dart';

/// 主题 JSON 导入与远程主题加载端口。
abstract interface class ThemeImportPort {
  LegadoThemeConfig parseJson(String raw);

  Future<LegadoThemeConfig> fetchFromUrl(String url);

  Future<void> applyTo(
    ThemeModeController controller,
    LegadoThemeConfig config,
  );
}

/// 主题端口所需的公开文本读取能力，供基础设施适配器组装依赖。
abstract interface class ThemeImportFetchPort implements PublicTextFetchPort {}
