import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/theme/app_theme.dart';
import 'package:legado_flutter/theme/color_presets.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  SharedPreferences.setMockInitialValues({});

  group('LegadoColorPresets', () {
    test('has at least 5 preset schemes', () {
      expect(LegadoColorPresets.all.length, greaterThanOrEqualTo(5));
      final labels = LegadoColorPresets.all.map((p) => p.label).toList();
      expect(labels, containsAll(['浅色', '深色', '护眼', '纸质', '夜间']));
    });

    test('each preset builds valid light and dark schemes', () {
      for (final info in LegadoColorPresets.all) {
        final light = LegadoColorPresets.schemeFor(info.id, Brightness.light);
        final dark = LegadoColorPresets.schemeFor(info.id, Brightness.dark);
        expect(light.brightness, Brightness.light);
        expect(dark.brightness, Brightness.dark);
        expect(light.primary, isNotNull);
        expect(dark.surface, isNotNull);
      }
    });

    test('dynamic preset uses system scheme when provided', () {
      const dynamicLight = ColorScheme(
        brightness: Brightness.light,
        primary: Color(0xFF123456),
        onPrimary: Colors.white,
        secondary: Color(0xFF654321),
        onSecondary: Colors.white,
        error: Colors.red,
        onError: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
      );
      final scheme = LegadoColorPresets.schemeFor(
        LegadoColorPreset.dynamic,
        Brightness.light,
        dynamicLight: dynamicLight,
      );
      expect(scheme.primary, const Color(0xFF123456));
    });

    test('exportConfig includes preset metadata', () {
      final json = LegadoColorPresets.exportConfig(
        mode: 'system',
        preset: LegadoColorPreset.paper,
      );
      expect(json['preset'], 'paper');
      expect(json['label'], '纸质');
      expect(json['seed'], startsWith('#'));
    });
  });

  group('ThemeModeController', () {
    test('defaults and preset persistence', () async {
      final ctrl = ThemeModeController();
      await ctrl.load();
      expect(ctrl.mode, LegadoThemeMode.system);
      expect(ctrl.preset, LegadoColorPreset.light);

      await ctrl.setPreset(LegadoColorPreset.night);
      expect(ctrl.preset, LegadoColorPreset.night);
      expect(ctrl.presetLabel, '夜间');

      final ctrl2 = ThemeModeController();
      await ctrl2.load();
      expect(ctrl2.preset, LegadoColorPreset.night);
    });

    test('AppTheme builds MD3 themes from preset', () {
      final theme = AppTheme.light(preset: LegadoColorPreset.eyeCare);
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, isNotNull);
      expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());
    });

    test('custom colors persist and apply', () async {
      final ctrl = ThemeModeController();
      await ctrl.load();
      await ctrl.setCustomColor('primary', const Color(0xFFE91E63));
      expect(ctrl.customColors['primary'], const Color(0xFFE91E63));

      final ctrl2 = ThemeModeController();
      await ctrl2.load();
      expect(ctrl2.customColors['primary'], const Color(0xFFE91E63));

      final theme = AppTheme.light(
        preset: LegadoColorPreset.light,
        customColors: ctrl2.customColors,
      );
      expect(theme.colorScheme.primary, const Color(0xFFE91E63));
    });

    test('exportConfig includes colors map', () async {
      final ctrl = ThemeModeController();
      await ctrl.load();
      await ctrl.setCustomColor('surface', const Color(0xFFF5F5F5));
      final json = ctrl.exportConfig();
      expect(json['colors'], isA<Map>());
    });
  });
}
