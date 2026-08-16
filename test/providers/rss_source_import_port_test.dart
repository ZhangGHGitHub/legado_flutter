import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/rss_source_import_port.dart';
import 'package:legado_flutter/providers/rss_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRssSourceImportPort implements RssSourceImportPort {
  _FakeRssSourceImportPort(this.content);

  final String? content;
  String? requestedUrl;

  @override
  Future<String?> fetch(String url) async {
    requestedUrl = url;
    return content;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('imports URL content through the injected port', () async {
    final port = _FakeRssSourceImportPort(
      '[{"sourceUrl":"https://example.com/rss","sourceName":"测试源"}]',
    );
    final provider = RssProvider(sourceImportPort: port);

    expect(
      await provider.importSourcesFromUrl('  https://example.com/list '),
      isTrue,
    );
    expect(port.requestedUrl, '  https://example.com/list ');
    expect(provider.sources.single.sourceName, '测试源');
  });

  test('returns false when the URL port cannot fetch content', () async {
    final provider = RssProvider(
      sourceImportPort: _FakeRssSourceImportPort(null),
    );

    expect(
      await provider.importSourcesFromUrl('https://example.com/list'),
      isFalse,
    );
    expect(provider.sources, isEmpty);
  });
}
