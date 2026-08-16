import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/models/source_validation_result.dart';
import 'package:legado_flutter/services/source_validation_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const sample = SourceValidationResult(
    searchOk: true,
    discoveryOk: false,
    tocOk: true,
    contentOk: false,
    searchTimeMs: 1200,
    errors: ['search timeout', 'content empty'],
  );

  group('resultToJson / resultFromJson', () {
    test('round-trips all fields', () {
      final json = resultToJson(sample);
      expect(json['searchOk'], isTrue);
      expect(json['discoveryOk'], isFalse);
      expect(json['tocOk'], isTrue);
      expect(json['contentOk'], isFalse);
      expect(json['searchTimeMs'], 1200);
      expect(json['errors'], ['search timeout', 'content empty']);

      final restored = resultFromJson(json);
      expect(restored.searchOk, sample.searchOk);
      expect(restored.discoveryOk, sample.discoveryOk);
      expect(restored.tocOk, sample.tocOk);
      expect(restored.contentOk, sample.contentOk);
      expect(restored.searchTimeMs, sample.searchTimeMs);
      expect(restored.errors, sample.errors);
    });

    test('defaults errors to empty list when missing', () {
      final restored = resultFromJson({
        'searchOk': true,
        'discoveryOk': true,
        'tocOk': true,
        'contentOk': true,
        'searchTimeMs': 0,
      });
      expect(restored.errors, isEmpty);
    });
  });

  group('SourceValidationStore', () {
    test('load returns empty map when unset', () async {
      expect(await SourceValidationStore.load(), isEmpty);
    });

    test('put and load round-trip', () async {
      const url = 'https://example.com/book';
      await SourceValidationStore.put(url, sample);

      final loaded = await SourceValidationStore.load();
      expect(loaded.length, 1);
      expect(loaded[url]!.searchOk, sample.searchOk);
      expect(loaded[url]!.discoveryOk, sample.discoveryOk);
      expect(loaded[url]!.errors, sample.errors);
    });

    test('saveAll replaces entire map', () async {
      await SourceValidationStore.put('https://a.com', sample);
      await SourceValidationStore.saveAll({
        'https://b.com': const SourceValidationResult(
          searchOk: true,
          discoveryOk: true,
          tocOk: true,
          contentOk: true,
          searchTimeMs: 50,
        ),
      });

      final loaded = await SourceValidationStore.load();
      expect(loaded.keys, {'https://b.com'});
      expect(loaded['https://b.com']!.searchTimeMs, 50);
    });

    test('remove deletes entry', () async {
      const url = 'https://example.com/book';
      await SourceValidationStore.put(url, sample);
      await SourceValidationStore.remove(url);

      expect(await SourceValidationStore.load(), isEmpty);
    });
  });
}
