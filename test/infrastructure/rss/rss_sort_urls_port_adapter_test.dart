import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/rss/rss_source.dart';
import 'package:legado_flutter/infrastructure/rss/rss_sort_urls_port_adapter.dart';
import 'package:legado_flutter/services/rss_sort_urls.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const source = RssSource(
    sourceUrl: 'https://example.com/rss',
    sourceName: '测试 RSS',
    sortUrl: '分类::https://example.com/category',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('adapter delegates resolve and cache clearing to RssSortUrls', () async {
    const adapter = RssSortUrlsPortAdapter();

    expect(await adapter.resolve(source), [
      ('分类', 'https://example.com/category'),
    ]);

    await adapter.clearCache(source);
    expect(await adapter.resolve(source), [
      ('分类', 'https://example.com/category'),
    ]);
  });

  tearDown(RssSortUrls.resetJsPort);
}
