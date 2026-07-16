import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppConfig.resetForTest();
  });

  tearDown(() {
    AppConfig.resetForTest();
  });

  test('defaults showDiscovery and showRSS to true', () async {
    final cfg = AppConfig.instance;
    await cfg.load();
    expect(cfg.showDiscovery, isTrue);
    expect(cfg.showRSS, isTrue);
  });

  test('persists tab visibility toggles', () async {
    final cfg = AppConfig.instance;
    await cfg.load();
    await cfg.setShowDiscovery(false);
    await cfg.setShowRSS(false);

    AppConfig.resetForTest();
    final again = AppConfig.instance;
    await again.load();
    expect(again.showDiscovery, isFalse);
    expect(again.showRSS, isFalse);
  });
}
