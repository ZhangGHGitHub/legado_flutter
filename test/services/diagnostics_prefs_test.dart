import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/preferences/shared_preferences_runtime.dart';
import 'package:legado_flutter/services/diagnostics_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferencesRuntime.resetForTest();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    SharedPreferencesRuntime.resetForTest();
  });

  test('diagnostics monitoring defaults to disabled and round-trips', () async {
    expect(await DiagnosticsPrefs.isMonitoringEnabled(), isFalse);

    await DiagnosticsPrefs.setMonitoringEnabled(true);
    expect(await DiagnosticsPrefs.isMonitoringEnabled(), isTrue);

    await DiagnosticsPrefs.setMonitoringEnabled(false);
    expect(await DiagnosticsPrefs.isMonitoringEnabled(), isFalse);
  });
}
