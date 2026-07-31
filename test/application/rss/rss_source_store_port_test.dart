import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/rss/rss_source_store_port.dart';
import 'package:legado_flutter/domain/rss/rss_source.dart';

final class _MemoryRssSourceStore implements RssSourceStorePort {
  _MemoryRssSourceStore(this._sources);

  List<RssSource> _sources;

  @override
  Future<List<RssSource>> load() async => List<RssSource>.from(_sources);

  @override
  Future<void> save(List<RssSource> sources) async {
    _sources = List<RssSource>.from(sources);
  }
}

void main() {
  test(
    'supports loading and saving the complete ordered source list',
    () async {
      final first = const RssSource(
        sourceUrl: 'https://example.com/first',
        sourceName: '第一源',
        customOrder: 2,
      );
      final second = const RssSource(
        sourceUrl: 'https://example.com/second',
        sourceName: '第二源',
        customOrder: 1,
      );
      final store = _MemoryRssSourceStore([first]);

      expect((await store.load()).single.sourceUrl, first.sourceUrl);

      await store.save([second, first]);

      final loaded = await store.load();
      expect(loaded.map((source) => source.sourceUrl), [
        second.sourceUrl,
        first.sourceUrl,
      ]);
      expect(loaded.map((source) => source.customOrder), [1, 2]);
    },
  );
}
