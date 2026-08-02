import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/rss/rss_controller.dart';
import 'package:legado_flutter/application/rss/rss_source_store_port.dart';
import 'package:legado_flutter/domain/rss/rss_source.dart';

void main() {
  test('loads sources and publishes an immutable state', () async {
    final source = const RssSource(
      sourceUrl: 'https://example.com/rss',
      sourceName: 'RSS',
    );
    final controller = RssSourceController(
      sourceStore: _FakeRssSourceStore([source]),
    );
    var notifications = 0;
    controller.addListener((_) => notifications++);

    await controller.loadSources();

    expect(controller.sources.single, source);
    expect(notifications, 1);
    expect(() => controller.sources.add(source), throwsUnsupportedError);
  });

  test('keeps URL de-duplication and managed sorting', () async {
    final controller = RssSourceController(
      sourceStore: _FakeRssSourceStore([]),
    );
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

    await controller.upsertSource(first);
    await controller.upsertSource(second);
    await controller.upsertSource(first.copyWith(sourceName: 'Updated'));

    expect(controller.sources, hasLength(2));
    expect(controller.managedSources().map((source) => source.sourceName), [
      'Alpha',
      'Updated',
    ]);
  });
}

class _FakeRssSourceStore implements RssSourceStorePort {
  _FakeRssSourceStore(this.sources);

  final List<RssSource> sources;

  @override
  Future<List<RssSource>> load() async => List<RssSource>.of(sources);

  @override
  Future<void> save(List<RssSource> sources) async {}
}
