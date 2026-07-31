import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:legado_flutter/domain/rss/rss_article.dart';
import 'package:legado_flutter/infrastructure/rss/rss_star_prefs_port_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('保留收藏顺序并可按源与链接移除', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'legado_rss_stars',
      '[{"origin":"source-a","link":"a","title":"A"},'
          '{"origin":"source-b","link":"b","title":"B"}]',
    );
    const adapter = RssStarPrefsPortAdapter();

    expect((await adapter.loadAll()).map((a) => a.link), ['a', 'b']);

    await adapter.remove('source-a', 'a');

    expect((await adapter.loadAll()).map((a) => a.link), ['b']);
  });

  test('缺失或空收藏值返回空列表', () async {
    const adapter = RssStarPrefsPortAdapter();

    expect(await adapter.loadAll(), isEmpty);
  });

  test('toggle 保留文章字段并返回收藏状态', () async {
    const adapter = RssStarPrefsPortAdapter();
    const article = RssArticle(
      origin: 'source-a',
      title: '文章',
      link: 'article-a',
      image: 'image-a',
    );

    expect(await adapter.toggle(article), isTrue);
    expect((await adapter.loadAll()).single.title, '文章');
    expect(await adapter.toggle(article), isFalse);
    expect(await adapter.loadAll(), isEmpty);
  });
}
