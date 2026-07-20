import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/services/check_source_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CheckSourcePrefs defaults', () {
    test('timeoutSec defaults to 30', () async {
      expect(await CheckSourcePrefs.timeoutSec(), 30);
    });

    test('check toggles default to true', () async {
      expect(await CheckSourcePrefs.checkSearch(), isTrue);
      expect(await CheckSourcePrefs.checkDiscovery(), isTrue);
      expect(await CheckSourcePrefs.checkToc(), isTrue);
      expect(await CheckSourcePrefs.checkContent(), isTrue);
    });

    test('lastKeyword defaults to empty', () async {
      expect(await CheckSourcePrefs.lastKeyword(), '');
    });
  });

  group('CheckSourcePrefs round-trip', () {
    test('persists timeout and toggles', () async {
      await CheckSourcePrefs.setTimeoutSec(45);
      await CheckSourcePrefs.setCheckSearch(false);
      await CheckSourcePrefs.setCheckDiscovery(false);
      await CheckSourcePrefs.setCheckToc(false);
      await CheckSourcePrefs.setCheckContent(false);

      expect(await CheckSourcePrefs.timeoutSec(), 45);
      expect(await CheckSourcePrefs.checkSearch(), isFalse);
      expect(await CheckSourcePrefs.checkDiscovery(), isFalse);
      expect(await CheckSourcePrefs.checkToc(), isFalse);
      expect(await CheckSourcePrefs.checkContent(), isFalse);
    });

    test('persists last keyword', () async {
      await CheckSourcePrefs.setLastKeyword('斗破');
      expect(await CheckSourcePrefs.lastKeyword(), '斗破');
    });
  });
}
