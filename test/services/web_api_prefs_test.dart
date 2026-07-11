import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/services/web_api_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  SharedPreferences.setMockInitialValues({});

  test('WebApiPrefs defaults and roundtrip', () async {
    final initial = await WebApiPrefs.load();
    expect(initial.enabled, isFalse);
    expect(initial.port, WebApiPrefs.defaultPort);

    await WebApiPrefs.save(
      const WebApiConfig(enabled: true, port: 2233, token: 'abc'),
    );
    final loaded = await WebApiPrefs.load();
    expect(loaded.enabled, isTrue);
    expect(loaded.port, 2233);
    expect(loaded.token, 'abc');
  });
}
