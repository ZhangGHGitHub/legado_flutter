import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:legado_flutter/application/rss/rss_star_prefs_port.dart';
import 'package:legado_flutter/domain/rss/rss_article.dart';
import 'package:legado_flutter/domain/rss/rss_source.dart';
import 'package:legado_flutter/features/rss/rss_favorites_page.dart';
import 'package:legado_flutter/providers/rss_provider.dart';

class _FakeRssStarPrefsPort implements RssStarPrefsPort {
  _FakeRssStarPrefsPort(this.items);

  final List<RssArticle> items;

  @override
  Future<List<RssArticle>> loadAll() async => List<RssArticle>.of(items);

  @override
  Future<bool> toggle(RssArticle article) async => false;

  @override
  Future<void> remove(String origin, String link) async {
    items.removeWhere((item) => item.origin == origin && item.link == link);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('RssFavoritesPage reads sources through the shared controller', (
    tester,
  ) async {
    final provider = RssProvider();
    await provider.upsertSource(
      const RssSource(sourceUrl: 'https://example.com/rss', sourceName: '示例订阅'),
    );
    final stars = _FakeRssStarPrefsPort([
      const RssArticle(
        origin: 'https://example.com/rss',
        title: '收藏文章',
        link: 'https://example.com/article',
      ),
    ]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          Provider<RssStarPrefsPort>.value(value: stars),
        ],
        child: const MaterialApp(home: RssFavoritesPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('收藏文章'), findsOneWidget);
    expect(find.text('https://example.com/rss'), findsOneWidget);
    expect(find.byTooltip('取消收藏'), findsOneWidget);

    await tester.tap(find.byTooltip('取消收藏'));
    await tester.pumpAndSettle();

    expect(find.text('暂无收藏'), findsOneWidget);
  });
}
