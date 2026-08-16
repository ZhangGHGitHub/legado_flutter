import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/rss/rss_source_store_port.dart';
import 'package:legado_flutter/domain/rss/rss_source.dart';
import 'package:legado_flutter/providers/rss_provider.dart';

final class _FakeRssSourceStore implements RssSourceStorePort {
  _FakeRssSourceStore(this.sources);

  List<RssSource> sources;
  var loadCalls = 0;
  var saveCalls = 0;
  List<RssSource>? savedSources;

  @override
  Future<List<RssSource>> load() async {
    loadCalls++;
    return List<RssSource>.from(sources);
  }

  @override
  Future<void> save(List<RssSource> sources) async {
    saveCalls++;
    savedSources = List<RssSource>.from(sources);
  }
}

void main() {
  test('loads and persists through the source store port', () async {
    final source = const RssSource(
      sourceUrl: 'https://example.com/rss',
      sourceName: 'RSS',
    );
    final store = _FakeRssSourceStore([source]);
    final provider = RssProvider(sourceStore: store);

    await provider.loadSources();
    expect(provider.sources.map((item) => item.sourceUrl), [source.sourceUrl]);
    expect(store.loadCalls, 1);

    await provider.upsertSource(source.copyWith(sourceName: '更新后'));

    expect(store.saveCalls, 1);
    expect(store.savedSources?.single.sourceName, '更新后');
  });

  test(
    'keeps source URL de-duplication and view sorting in the provider',
    () async {
      final first = const RssSource(
        sourceUrl: 'https://example.com/first',
        sourceName: 'Zeta',
        customOrder: 1,
      );
      final second = const RssSource(
        sourceUrl: 'https://example.com/second',
        sourceName: 'Alpha',
        customOrder: 3,
      );
      final store = _FakeRssSourceStore([]);
      final provider = RssProvider(sourceStore: store);

      await provider.upsertSource(first);
      await provider.upsertSource(second);
      await provider.upsertSource(first.copyWith(sourceName: 'Updated'));

      expect(provider.sources, hasLength(2));
      expect(provider.managedSources().map((source) => source.sourceName), [
        'Alpha',
        'Updated',
      ]);
      expect(store.savedSources?.map((source) => source.sourceUrl), [
        first.sourceUrl,
        second.sourceUrl,
      ]);
    },
  );
}
