import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:legado_flutter/infrastructure/preferences/shared_preferences_rss_read_state_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('按编码后的 RSS 源 URL 读写已读链接集合', () async {
    final prefs = await SharedPreferences.getInstance();
    final adapter = SharedPreferencesRssReadStateAdapter(prefs);
    const sourceUrl = 'https://example.com/rss?tag=中文&kind=all';

    await adapter.write(sourceUrl, ['article-1', 'article-2']);

    expect(prefs.getStringList('rss_read_${Uri.encodeComponent(sourceUrl)}'), [
      'article-1',
      'article-2',
    ]);
    expect(await adapter.read(sourceUrl), {'article-1', 'article-2'});
  });

  test('未保存的 RSS 源返回空集合并保留重复链接的集合语义', () async {
    final prefs = await SharedPreferences.getInstance();
    final adapter = SharedPreferencesRssReadStateAdapter(prefs);

    expect(await adapter.read('https://example.com/empty'), isEmpty);

    await adapter.write('https://example.com/empty', ['a', 'a', 'b']);
    expect(await adapter.read('https://example.com/empty'), {'a', 'b'});
  });

  test('SharedPreferences 不可用时读为空且写入不抛错', () async {
    const adapter = SharedPreferencesRssReadStateAdapter(null);

    expect(await adapter.read('https://example.com/unavailable'), isEmpty);
    await adapter.write('https://example.com/unavailable', ['article']);
  });
}
