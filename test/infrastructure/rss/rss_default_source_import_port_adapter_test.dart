import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/rss/rss_controller.dart';
import 'package:legado_flutter/application/rss/rss_source_store_port.dart';
import 'package:legado_flutter/domain/rss/rss_source.dart';
import 'package:legado_flutter/infrastructure/rss/rss_default_source_import_port_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the registered original default RSS JSON asset', () async {
    final store = _RecordingStore();
    final controller = RssSourceController(sourceStore: store);
    final adapter = RssDefaultSourceImportPortAdapter(controller);

    expect(await adapter.importDefaults(), isTrue);
    expect(controller.sources, hasLength(4));
    expect(
      controller.sources.where((source) => source.sourceGroup == 'legado'),
      hasLength(2),
    );
    expect(
      controller.sources
          .singleWhere((source) => source.sourceName == '源仓库')
          .raw['loginUrl'],
      isNotEmpty,
    );
    expect(store.saved, hasLength(1));
  });
}

class _RecordingStore implements RssSourceStorePort {
  final saved = <List<RssSource>>[];

  @override
  Future<List<RssSource>> load() async => const [];

  @override
  Future<void> save(List<RssSource> sources) async {
    saved.add(List<RssSource>.of(sources));
  }
}
