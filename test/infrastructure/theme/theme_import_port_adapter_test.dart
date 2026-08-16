import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/public_text_fetch_port.dart';
import 'package:legado_flutter/infrastructure/theme/theme_import_port_adapter.dart';
import 'package:legado_flutter/theme/app_theme.dart';
import 'package:legado_flutter/theme/color_presets.dart';

class _FakePublicTextFetchPort implements PublicTextFetchPort {
  _FakePublicTextFetchPort(this.body);

  final String body;
  String? requestedUrl;

  @override
  Future<String> fetch(String url, {String userAgent = ''}) async {
    requestedUrl = url;
    return body;
  }
}

void main() {
  test('adapter exposes JSON parsing and applies the config', () async {
    final port = ThemeImportPortAdapter(_FakePublicTextFetchPort('{}'));
    final controller = ThemeModeController();
    await controller.load();

    final config = port.parseJson(
      '{"version":"1","mode":"dark","preset":"night",'
      '"colors":{"primary":"#FF5722"}}',
    );
    await port.applyTo(controller, config);

    expect(controller.mode, LegadoThemeMode.dark);
    expect(controller.preset, LegadoColorPreset.night);
    expect(controller.customColors['primary'], const Color(0xFFFF5722));
  });

  test(
    'adapter preserves URL validation and delegates public text loading',
    () async {
      final fetchPort = _FakePublicTextFetchPort(
        '{"version":"1","preset":"paper"}',
      );
      final port = ThemeImportPortAdapter(fetchPort);

      final config = await port.fetchFromUrl(
        '  https://example.test/theme.json ',
      );

      expect(fetchPort.requestedUrl, 'https://example.test/theme.json');
      expect(config.preset, 'paper');
    },
  );

  test('adapter preserves invalid JSON errors', () {
    final port = ThemeImportPortAdapter(_FakePublicTextFetchPort('{}'));

    expect(() => port.parseJson('[]'), throwsA(isA<FormatException>()));
  });
}
