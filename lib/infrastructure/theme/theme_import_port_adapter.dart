import '../../application/theme/theme_import_port.dart';
import '../../domain/ports/public_text_fetch_port.dart';
import '../../services/theme_import_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_config_model.dart';

/// 将现有主题导入服务适配到应用端口。
final class ThemeImportPortAdapter implements ThemeImportPort {
  ThemeImportPortAdapter(this._fetchPort)
    : _service = const ThemeImportService();

  final PublicTextFetchPort _fetchPort;
  final ThemeImportService _service;

  @override
  LegadoThemeConfig parseJson(String raw) => _service.parseJson(raw);

  @override
  Future<LegadoThemeConfig> fetchFromUrl(String url) {
    return _service.fetchFromUrl(url, fetchPort: _fetchPort);
  }

  @override
  Future<void> applyTo(
    ThemeModeController controller,
    LegadoThemeConfig config,
  ) {
    return _service.applyTo(controller, config);
  }
}
