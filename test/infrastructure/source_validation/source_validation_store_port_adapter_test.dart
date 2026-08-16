import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/source/source_validation_result.dart';
import 'package:legado_flutter/infrastructure/source_validation/source_validation_store_port_adapter.dart';
import 'package:legado_flutter/services/source_validation_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const firstUrl = 'https://source.example/path';
  const secondUrl = 'https://source.example/path/';
  const firstResult = SourceValidationResult(
    searchOk: true,
    discoveryOk: false,
    tocOk: true,
    contentOk: false,
    searchTimeMs: 321,
    errors: ['discovery failed', 'content empty'],
  );
  const secondResult = SourceValidationResult(
    searchOk: false,
    discoveryOk: true,
    tocOk: false,
    contentOk: true,
    searchTimeMs: 654,
    errors: ['search failed'],
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'uses source_validation_v1 and round-trips every result field',
    () async {
      const port = SourceValidationStorePortAdapter();

      await port.put(firstUrl, firstResult);

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(SourceValidationStore.storeKey);
      expect(raw, isNotNull);
      expect((jsonDecode(raw!) as Map<String, dynamic>).keys, [firstUrl]);

      final loaded = await port.load();
      final restored = loaded[firstUrl]!;
      expect(restored.searchOk, firstResult.searchOk);
      expect(restored.discoveryOk, firstResult.discoveryOk);
      expect(restored.tocOk, firstResult.tocOk);
      expect(restored.contentOk, firstResult.contentOk);
      expect(restored.searchTimeMs, firstResult.searchTimeMs);
      expect(restored.errors, firstResult.errors);
    },
  );

  test('returns an empty map for missing, empty and damaged data', () async {
    const port = SourceValidationStorePortAdapter();

    expect(await port.load(), isEmpty);

    SharedPreferences.setMockInitialValues({
      SourceValidationStore.storeKey: '',
    });
    expect(await port.load(), isEmpty);

    SharedPreferences.setMockInitialValues({
      SourceValidationStore.storeKey: '{not-json',
    });
    expect(await port.load(), isEmpty);

    SharedPreferences.setMockInitialValues({
      SourceValidationStore.storeKey: jsonEncode(['not', 'a', 'map']),
    });
    expect(await port.load(), isEmpty);
  });

  test(
    'put and remove preserve exact URL keys and unrelated entries',
    () async {
      const port = SourceValidationStorePortAdapter();

      await port.put(firstUrl, firstResult);
      await port.put(secondUrl, secondResult);

      final loaded = await port.load();
      expect(loaded.keys, containsAll(<String>[firstUrl, secondUrl]));
      expect(loaded[firstUrl]!.searchTimeMs, 321);
      expect(loaded[secondUrl]!.searchTimeMs, 654);

      await port.remove(firstUrl);

      final remaining = await port.load();
      expect(remaining, isNot(contains(firstUrl)));
      expect(remaining[secondUrl]!.errors, secondResult.errors);
    },
  );
}
