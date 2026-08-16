import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/preferences/shared_preferences_runtime.dart';
import 'package:legado_flutter/infrastructure/preferences/shared_preferences_source_variable_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesRuntime.resetForTest();
  });

  tearDown(SharedPreferencesRuntime.resetForTest);

  test('reads and writes source variables with the legacy key', () async {
    SharedPreferences.setMockInitialValues({
      'source_variable:https://example.test/source': 'old value',
    });
    SharedPreferencesRuntime.resetForTest();
    final adapter = await SharedPreferencesSourceVariableAdapter.create();

    expect(await adapter.read('https://example.test/source'), 'old value');
    expect(
      await adapter.write('https://example.test/source', 'new value'),
      isTrue,
    );
    expect(await adapter.read('https://example.test/source'), 'new value');
  });

  test(
    'degrades to an empty value when preference storage is unavailable',
    () async {
      SharedPreferencesRuntime.setLoaderForTest(() async {
        throw StateError('platform unavailable');
      });
      final adapter = await SharedPreferencesSourceVariableAdapter.create();

      expect(await adapter.read('source'), isEmpty);
      expect(await adapter.write('source', 'value'), isFalse);
    },
  );
}
