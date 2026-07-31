import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/preferences/shared_preferences_runtime.dart';
import 'package:legado_flutter/infrastructure/main/privacy_consent_port_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesRuntime.resetForTest();
  });

  tearDown(SharedPreferencesRuntime.resetForTest);

  test('preserves the legacy key and round-trips consent', () async {
    final adapter = await SharedPreferencesPrivacyConsentPortAdapter.create();

    expect(await adapter.isAccepted(), isFalse);
    expect(await adapter.saveAccepted(), isTrue);
    expect(await adapter.isAccepted(), isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getBool(SharedPreferencesPrivacyConsentPortAdapter.acceptedKey),
      isTrue,
    );
  });

  test('degrades to false when preference runtime is unavailable', () async {
    SharedPreferencesRuntime.setLoaderForTest(() async {
      throw StateError('platform unavailable');
    });
    final adapter = await SharedPreferencesPrivacyConsentPortAdapter.create();

    expect(await adapter.isAccepted(), isFalse);
    expect(await adapter.saveAccepted(), isFalse);
  });
}
