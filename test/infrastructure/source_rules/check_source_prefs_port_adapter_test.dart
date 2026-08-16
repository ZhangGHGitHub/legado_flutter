import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/infrastructure/source_rules/check_source_prefs_port_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('preserves source-check defaults and preference keys', () async {
    const adapter = CheckSourcePrefsPortAdapter();

    expect(await adapter.timeoutSec(), 30);
    expect(await adapter.checkSearch(), isTrue);
    expect(await adapter.checkDiscovery(), isTrue);
    expect(await adapter.checkToc(), isTrue);
    expect(await adapter.checkContent(), isTrue);
    expect(await adapter.showDebugMessage(), isTrue);
    expect(await adapter.lastKeyword(), '');

    await adapter.setTimeoutSec(45);
    await adapter.setCheckSearch(false);
    await adapter.setCheckDiscovery(false);
    await adapter.setCheckToc(false);
    await adapter.setCheckContent(false);
    await adapter.setShowDebugMessage(false);
    await adapter.setLastKeyword('斗破');

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getInt('check_source_timeout_sec'), 45);
    expect(preferences.getBool('check_search'), isFalse);
    expect(preferences.getBool('check_discovery'), isFalse);
    expect(preferences.getBool('check_toc'), isFalse);
    expect(preferences.getBool('check_content'), isFalse);
    expect(preferences.getBool('check_source_show_debug_message'), isFalse);
    expect(preferences.getString('check_source_last_keyword'), '斗破');
  });
}
