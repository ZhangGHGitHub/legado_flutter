import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/public_text_fetch_port.dart';
import 'package:legado_flutter/services/theme_import_service.dart';
import 'package:legado_flutter/theme/app_theme.dart';
import 'package:legado_flutter/theme/theme_config_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class _FakePublicTextFetchPort implements PublicTextFetchPort {
  _FakePublicTextFetchPort({this.result = '', this.error});

  final String result;
  final Object? error;
  String? requestedUrl;

  @override
  Future<String> fetch(String url, {String userAgent = ''}) async {
    requestedUrl = url;
    if (error != null) throw error!;
    return result;
  }
}

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
    const service = ThemeImportService();

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
          colors: {'primary': Color(0xFF00FF00)},
        ),
      );
      expect(ctrl.mode, LegadoThemeMode.light);
      expect(ctrl.preset.name, 'paper');
      expect(ctrl.customColors['primary'], const Color(0xFF00FF00));
    });

    test('fetchFromUrl uses the public text port and trims the URL', () async {
      final fetchPort = _FakePublicTextFetchPort(
        result: '{"mode":"dark","preset":"night"}',
      );

      final config = await service.fetchFromUrl(
        '  https://example.com/theme.json  ',
        fetchPort: fetchPort,
      );

      expect(fetchPort.requestedUrl, 'https://example.com/theme.json');
      expect(config.mode, 'dark');
      expect(config.preset, 'night');
    });

    test('fetchFromUrl rejects an empty response', () async {
      expect(
        service.fetchFromUrl(
          'https://example.com/theme.json',
          fetchPort: _FakePublicTextFetchPort(result: '  '),
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            '主题 URL 返回空内容',
          ),
        ),
      );
    });

    test('fetchFromUrl preserves public text port errors', () async {
      expect(
        service.fetchFromUrl(
          'https://example.com/theme.json',
          fetchPort: _FakePublicTextFetchPort(error: StateError('offline')),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('fetchFromUrl rejects private addresses before fetching', () async {
      final fetchPort = _FakePublicTextFetchPort(result: '{}');

      expect(
        service.fetchFromUrl(
          'http://127.0.0.1/theme.json',
          fetchPort: fetchPort,
        ),
        throwsA(isA<FormatException>()),
      );
      expect(fetchPort.requestedUrl, isNull);
    });
  });
}
