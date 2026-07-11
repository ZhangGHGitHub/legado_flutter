import 'dart:convert';

import 'package:dio/dio.dart';

import '../theme/app_theme.dart';
import '../theme/color_presets.dart';
import '../theme/theme_config_model.dart';

/// 主题 JSON 导入/市场加载（Phase 4.1）
class ThemeImportService {
  ThemeImportService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  LegadoThemeConfig parseJson(String raw) {
    final dynamic decoded = jsonDecode(raw.trim());
    if (decoded is! Map) {
      throw const FormatException('主题 JSON 须为对象');
    }
    final map = Map<String, dynamic>.from(decoded);
    final version = map['version']?.toString() ?? '1';
    final mode = map['mode']?.toString();
    final preset = map['preset']?.toString();
    Map<String, dynamic>? colorsRaw;
    final colorsVal = map['colors'];
    if (colorsVal is Map) {
      colorsRaw = Map<String, dynamic>.from(colorsVal);
    }
    return LegadoThemeConfig(
      version: version,
      mode: mode,
      preset: preset,
      colors: ThemeColorRoles.colorsFromHex(colorsRaw),
    );
  }

  Future<LegadoThemeConfig> fetchFromUrl(String url) async {
    final response = await _dio.get<String>(
      url.trim(),
      options: Options(
        responseType: ResponseType.plain,
        receiveTimeout: const Duration(seconds: 20),
        headers: const {'Accept': 'application/json, text/plain, */*'},
      ),
    );
    final body = response.data;
    if (body == null || body.trim().isEmpty) {
      throw const FormatException('主题 URL 返回空内容');
    }
    return parseJson(body);
  }

  Future<void> applyTo(
    ThemeModeController controller,
    LegadoThemeConfig config,
  ) async {
    if (config.mode != null) {
      final mode = LegadoThemeMode.values.firstWhere(
        (m) => m.name == config.mode,
        orElse: () => controller.mode,
      );
      await controller.setMode(mode);
    }
    if (config.preset != null) {
      await controller.setPreset(LegadoColorPresets.parse(config.preset));
    }
    await controller.setCustomColors(config.colors);
  }
}
