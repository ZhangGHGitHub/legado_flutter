import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_lib;
import 'package:legado_flutter/application/reader/reader_font_port.dart';
import '../helpers/fake_reader_font_port.dart';
import 'package:legado_flutter/application/rss/rss_read_state_port.dart';
import 'package:legado_flutter/application/rss/rss_star_prefs_port.dart';
import 'package:legado_flutter/domain/ports/application_binary_http_request_port.dart';
import 'package:legado_flutter/domain/ports/application_http_request_port.dart';
import 'package:legado_flutter/domain/ports/rss_port.dart';
import 'package:legado_flutter/domain/rss/rss_article.dart';
import 'package:legado_flutter/domain/rss/rss_source.dart';
import 'package:legado_flutter/features/rss/rss_articles_page.dart';
import 'package:legado_flutter/features/rss/rss_favorites_page.dart';
import 'package:legado_flutter/features/rss/widgets/rss_source_tile.dart';
import 'package:legado_flutter/services/rss_service.dart';
import 'package:legado_flutter/infrastructure/rss/rss_star_prefs_port_adapter.dart';
import 'package:legado_flutter/widgets/remote_binary_image.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeBinaryHttpPort implements ApplicationBinaryHttpRequestPort {
  final body = Uint8List.fromList(
    image_lib.encodePng(image_lib.Image(width: 2, height: 3)),
  );
  final requests = <({String url, ApplicationHttpPolicy policy})>[];

  @override
  Future<ApplicationBinaryHttpResponse> send({
    required String url,
    required String method,
    Map<String, String> headers = const {},
    Uint8List? body,
    int timeoutSeconds = 30,
    int maxResponseBytes = 0,
    required ApplicationHttpPolicy policy,
  }) async {
    requests.add((url: url, policy: policy));
    return ApplicationBinaryHttpResponse(
      statusCode: 200,
      contentType: 'image/png',
      body: this.body,
    );
  }
}

class _FakeRssPort implements RssPort {
  const _FakeRssPort(this.article);

  final RssArticle article;

  @override
  bool get isAvailable => true;

  @override
  Future<RssArticlesResult> getArticles({
    required RssSource source,
    required String sortName,
    required String sortUrl,
    required int page,
  }) async => RssArticlesResult(articles: [article]);

  @override
  Future<String> getContent({
    required RssSource source,
    required RssArticle article,
  }) async => article.content ?? '';
}

class _FakeReaderFontPort extends FakeReaderFontPort {
  @override
  String platformSansFamily() => 'TestSans';

  @override
  List<String> cjkFallbackFamilies() => const ['TestCjk', 'sans-serif'];
}

class _FakeRssReadStatePort implements RssReadStatePort {
  @override
  Future<Set<String>> read(String sourceUrl) async => <String>{};

  @override
  Future<void> write(String sourceUrl, Iterable<String> links) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RemoteBinaryImage.clearMemoryCache();
  });

  tearDown(RssService.resetRssPort);

  testWidgets('RSS source icon uses the local-network binary port', (
    tester,
  ) async {
    final port = _FakeBinaryHttpPort();
    await tester.pumpWidget(
      Provider<ApplicationBinaryHttpRequestPort>.value(
        value: port,
        child: Provider<ReaderFontPort>.value(
          value: _FakeReaderFontPort(),
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 180,
                height: 180,
                child: RssSourceTile(
                  name: '本地订阅',
                  icon: Icons.rss_feed,
                  iconUrl: 'http://192.168.1.2/icon.png',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final image = tester.widget<RemoteBinaryImage>(
      find.byType(RemoteBinaryImage),
    );
    expect(image.width, 50);
    expect(image.height, 50);
    expect(image.fit, BoxFit.cover);
    expect(image.policy, ApplicationHttpPolicy.localNetwork);
    expect(port.requests, [
      (
        url: 'http://192.168.1.2/icon.png',
        policy: ApplicationHttpPolicy.localNetwork,
      ),
    ]);
  });

  testWidgets('RSS article image uses the local-network binary port', (
    tester,
  ) async {
    const imageUrl = 'http://localhost:8080/article.png';
    const article = RssArticle(
      origin: 'http://localhost:8080/feed',
      title: '文章',
      link: 'http://localhost:8080/article',
      image: imageUrl,
    );
    RssService.configureRssPort(const _FakeRssPort(article));
    final port = _FakeBinaryHttpPort();

    await tester.pumpWidget(
      Provider<ApplicationBinaryHttpRequestPort>.value(
        value: port,
        child: Provider<ReaderFontPort>.value(
          value: _FakeReaderFontPort(),
          child: Provider<RssReadStatePort>.value(
            value: _FakeRssReadStatePort(),
            child: Provider<RssStarPrefsPort>.value(
              value: const RssStarPrefsPortAdapter(),
              child: const MaterialApp(
                home: RssArticlesPage(
                  source: RssSource(
                    sourceUrl: 'http://localhost:8080/feed',
                    sourceName: '本地源',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final image = tester.widget<RemoteBinaryImage>(
      find.byType(RemoteBinaryImage),
    );
    expect(image.width, 56);
    expect(image.height, 56);
    expect(image.fit, BoxFit.cover);
    expect(image.policy, ApplicationHttpPolicy.localNetwork);
    expect(port.requests.single.policy, ApplicationHttpPolicy.localNetwork);
  });

  testWidgets('RSS favorite image uses the local-network binary port', (
    tester,
  ) async {
    const imageUrl = 'http://127.0.0.1:8080/favorite.png';
    SharedPreferences.setMockInitialValues({
      'legado_rss_stars': jsonEncode([
        {
          'origin': 'http://127.0.0.1:8080/feed',
          'title': '收藏文章',
          'link': 'http://127.0.0.1:8080/article',
          'image': imageUrl,
        },
      ]),
    });
    final port = _FakeBinaryHttpPort();

    await tester.pumpWidget(
      Provider<ApplicationBinaryHttpRequestPort>.value(
        value: port,
        child: Provider<ReaderFontPort>.value(
          value: _FakeReaderFontPort(),
          child: Provider<RssStarPrefsPort>.value(
            value: const RssStarPrefsPortAdapter(),
            child: const MaterialApp(home: RssFavoritesPage()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final image = tester.widget<RemoteBinaryImage>(
      find.byType(RemoteBinaryImage),
    );
    expect(image.width, 48);
    expect(image.height, 48);
    expect(image.fit, BoxFit.cover);
    expect(image.policy, ApplicationHttpPolicy.localNetwork);
    expect(port.requests.single.policy, ApplicationHttpPolicy.localNetwork);
  });
}
