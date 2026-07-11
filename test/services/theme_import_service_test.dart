import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/services/theme_import_service.dart';
import 'package:legado_flutter/theme/app_theme.dart';
import 'package:legado_flutter/theme/theme_config_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  group('ThemeColorRoles', () {
    test('defines 12 MD3 color roles', () {
      expect(ThemeColorRoles.all.length, 12);
    });

    test('hex roundtrip', () {
      const color = Color(0xFF2196F3);
      final hex = ThemeColorRoles.toHex(color);
      expect(ThemeColorRoles.fromHex(hex), color);
    });

    test('applyOverrides updates scheme', () {
      const base = ColorScheme.light();
      final out = ThemeColorRoles.applyOverrides(base, {
        'primary': const Color(0xFFE91E63),
      });
      expect(out.primary, const Color(0xFFE91E63));
    });
  });

  group('ThemeImportService', () {
    final service = ThemeImportService();

    test('parseJson with preset and colors', () {
      final config = service.parseJson('''
        {
          "version": "1",
          "mode": "dark",
          "preset": "night",
          "colors": { "primary": "#FF0000" }
        }
      ''');
      expect(config.mode, 'dark');
      expect(config.preset, 'night');
      expect(config.colors['primary'], const Color(0xFFFF0000));
    });

    test('applyTo updates controller', () async {
      final ctrl = ThemeModeController();
      await ctrl.load();
      await service.applyTo(
        ctrl,
        const LegadoThemeConfig(
          mode: 'light',
          preset: 'paper',
          colors: { 'primary': Color(0xFF00FF00) },
        ),
      );
      expect(ctrl.mode, LegadoThemeMode.light);
      expect(ctrl.preset.name, 'paper');
      expect(ctrl.customColors['primary'], const Color(0xFF00FF00));
    });
  });
}
