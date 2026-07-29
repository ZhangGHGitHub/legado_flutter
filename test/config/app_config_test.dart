import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/config/app_config.dart';
import 'package:legado_flutter/application/preferences/shared_preferences_runtime.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesRuntime.resetForTest();
    AppConfig.resetForTest();
  });

  tearDown(() {
    AppConfig.resetForTest();
    SharedPreferencesRuntime.resetForTest();
  });

  test('defaults visibility and book progress sync to true', () async {
    final cfg = AppConfig.instance;
    await cfg.load();
    expect(cfg.showDiscovery, isTrue);
    expect(cfg.showRSS, isTrue);
    expect(cfg.syncBookProgress, isTrue);
  });

  test('persists tab visibility toggles', () async {
    final cfg = AppConfig.instance;
    await cfg.load();
    await cfg.setShowDiscovery(false);
    await cfg.setShowRSS(false);
    await cfg.setSyncBookProgress(false);

    AppConfig.resetForTest();
    final again = AppConfig.instance;
    await again.load();
    expect(again.showDiscovery, isFalse);
    expect(again.showRSS, isFalse);
    expect(again.syncBookProgress, isFalse);
  });

  test(
    'uses in-memory defaults when preference initialization fails',
    () async {
      SharedPreferencesRuntime.setLoaderForTest(() async {
        throw StateError('platform unavailable');
      });

      final cfg = AppConfig.instance;
      await cfg.load();
      await cfg.setShowDiscovery(false);

      expect(cfg.isLoaded, isTrue);
      expect(cfg.showDiscovery, isFalse);
      expect(
        SharedPreferencesRuntime.state,
        SharedPreferencesRuntimeState.failed,
      );
    },
  );
}
