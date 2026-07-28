import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/rss_sort_url_js_port.dart';
import 'package:legado_flutter/models/rss_source.dart';
import 'package:legado_flutter/services/rss_sort_urls.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSortUrlJsPort implements RssSortUrlJsPort {
  _FakeSortUrlJsPort({this.available = true});

  final bool available;
  final scripts = <String>[];

  @override
  bool get isAvailable => available;

  @override
  String evaluate({required RssSource source, required String script}) {
    scripts.add(script);
    return '分类一::https://example.com/one&&分类二::https://example.com/two';
  }
}

void main() {
  const source = RssSource(
    sourceUrl: 'https://example.com/rss',
    sourceName: '测试 RSS',
    sortUrl: '<JS>return "分类一::https://example.com/one";</JS>',
    jsLib: 'const helper = 1;',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RssSortUrls.resetJsPort();
  });

  tearDown(RssSortUrls.resetJsPort);

  test('sortUrl JS is evaluated through the port and cached', () async {
    final port = _FakeSortUrlJsPort();
    RssSortUrls.configureJsPort(port);

    final first = await RssSortUrls.resolve(source);
    final second = await RssSortUrls.resolve(source);

    expect(first.map((item) => item.$1), ['分类一', '分类二']);
    expect(first.map((item) => item.$2), [
      'https://example.com/one',
      'https://example.com/two',
    ]);
    expect(second, first);
    expect(port.scripts, ['return "分类一::https://example.com/one";']);
  });

  test(
    'plain sortUrl skips JS and unavailable JS falls back to source URL',
    () async {
      const plain = RssSource(
        sourceUrl: 'https://example.com/rss',
        sourceName: '测试 RSS',
        sortUrl: '分类::https://example.com/category',
      );
      final port = _FakeSortUrlJsPort(available: false);
      RssSortUrls.configureJsPort(port);

      expect(
        (await RssSortUrls.resolve(plain)).single.$2,
        'https://example.com/category',
      );
      expect((await RssSortUrls.resolve(source)).single.$2, source.sourceUrl);
      expect(port.scripts, isEmpty);
    },
  );
}
