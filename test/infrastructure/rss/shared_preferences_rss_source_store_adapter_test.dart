import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/rss/rss_source.dart';
import 'package:legado_flutter/infrastructure/rss/shared_preferences_rss_source_store_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('preserves the existing key, source order, and null fields', () async {
    final prefs = await SharedPreferences.getInstance();
    const adapter = SharedPreferencesRssSourceStoreAdapter();
    const later = RssSource(
      sourceUrl: 'https://example.com/later',
      sourceName: '后置',
      customOrder: 2,
    );
    const earlier = RssSource(
      sourceUrl: 'https://example.com/earlier',
      sourceName: '前置',
      customOrder: 1,
      loginUrl: null,
    );

    await adapter.save([later, earlier]);

    expect(prefs.getString('legado_rss_sources'), isNotNull);
    final stored = jsonDecode(prefs.getString('legado_rss_sources')!) as List;
    expect((stored.first as Map)['sourceUrl'], later.sourceUrl);

    final loaded = await adapter.load();
    expect(loaded.map((source) => source.sourceUrl), [
      later.sourceUrl,
      earlier.sourceUrl,
    ]);
    expect(loaded.last.loginUrl, isNull);
    expect(loaded.map((source) => source.customOrder), [2, 1]);
  });

  test('returns an empty list for missing, empty, or invalid values', () async {
    final prefs = await SharedPreferences.getInstance();
    const adapter = SharedPreferencesRssSourceStoreAdapter();

    expect(await adapter.load(), isEmpty);

    await prefs.setString('legado_rss_sources', '');
    expect(await adapter.load(), isEmpty);

    await prefs.setString('legado_rss_sources', '{not-json');
    expect(await adapter.load(), isEmpty);
  });

  test(
    'filters source entries without a URL and keeps duplicate URLs',
    () async {
      final prefs = await SharedPreferences.getInstance();
      const adapter = SharedPreferencesRssSourceStoreAdapter();
      await prefs.setString(
        'legado_rss_sources',
        jsonEncode([
          {'sourceUrl': '', 'sourceName': '无 URL'},
          {'sourceUrl': 'https://example.com/rss', 'sourceName': '一'},
          {'sourceUrl': 'https://example.com/rss', 'sourceName': '二'},
        ]),
      );

      final loaded = await adapter.load();

      expect(loaded.map((source) => source.sourceName), ['一', '二']);
    },
  );
}
