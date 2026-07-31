import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}
