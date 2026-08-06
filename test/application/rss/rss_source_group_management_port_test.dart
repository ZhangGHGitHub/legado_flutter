import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/rss/rss_controller.dart';
import 'package:legado_flutter/application/rss/rss_source_group_management_port.dart';
import 'package:legado_flutter/application/rss/rss_source_store_port.dart';
import 'package:legado_flutter/domain/rss/rss_source.dart';
import 'package:legado_flutter/infrastructure/rss/rss_source_group_management_port_adapter.dart';

void main() {
  test(
    'lists groups using the legacy separators and de-duplicates them',
    () async {
      final store = _RecordingRssSourceStore([
        const RssSource(
          sourceUrl: 'https://example.com/one',
          sourceName: '一',
          sourceGroup: '甲；乙,甲',
        ),
        const RssSource(
          sourceUrl: 'https://example.com/two',
          sourceName: '二',
          sourceGroup: '丙',
        ),
      ]);
      final controller = RssSourceController(sourceStore: store);
      await controller.loadSources();
      final port = _port(controller);

      expect(port.allGroups(), containsAll(<String>['甲', '乙', '丙']));
      expect(port.allGroups(), hasLength(3));
    },
  );

  test(
    'new group assigns ungrouped sources and persists sourceGroup',
    () async {
      final store = _RecordingRssSourceStore([
        const RssSource(
          sourceUrl: 'https://example.com/empty',
          sourceName: '未分组',
        ),
        const RssSource(
          sourceUrl: 'https://example.com/existing',
          sourceName: '已有分组',
          sourceGroup: '已有',
        ),
      ]);
      final controller = RssSourceController(sourceStore: store);
      await controller.loadSources();
      await _port(controller).addGroup('新组');

      expect(
        controller.sources
            .singleWhere((source) => source.sourceName == '未分组')
            .sourceGroup,
        '新组',
      );
      expect(
        store.saved.last,
        contains(
          isA<RssSource>().having(
            (source) => source.sourceGroup,
            'sourceGroup',
            '新组',
          ),
        ),
      );
    },
  );

  test(
    'renames and deletes a group without losing other group memberships',
    () async {
      final store = _RecordingRssSourceStore([
        const RssSource(
          sourceUrl: 'https://example.com/one',
          sourceName: '一',
          sourceGroup: '旧组,保留组',
        ),
        const RssSource(
          sourceUrl: 'https://example.com/two',
          sourceName: '二',
          sourceGroup: '旧组；另一组',
        ),
      ]);
      final controller = RssSourceController(sourceStore: store);
      await controller.loadSources();
      final port = _port(controller);

      await port.renameGroup('旧组', '新组');
      expect(controller.sources[0].sourceGroup, '保留组,新组');
      expect(controller.sources[1].sourceGroup, '另一组,新组');

      await port.deleteGroup('新组');
      expect(controller.sources[0].sourceGroup, '保留组');
      expect(controller.sources[1].sourceGroup, '另一组');
      expect(port.allGroups(), containsAll(<String>['保留组', '另一组']));
      expect(port.allGroups(), isNot(contains('新组')));
    },
  );
}

RssSourceGroupManagementPort _port(RssSourceController controller) =>
    RssSourceGroupManagementPortAdapter(controller);

class _RecordingRssSourceStore implements RssSourceStorePort {
  _RecordingRssSourceStore(Iterable<RssSource> sources)
    : _sources = List<RssSource>.of(sources);

  List<RssSource> _sources;
  final saved = <List<RssSource>>[];

  @override
  Future<List<RssSource>> load() async => List<RssSource>.of(_sources);

  @override
  Future<void> save(List<RssSource> sources) async {
    _sources = List<RssSource>.of(sources);
    saved.add(_sources);
  }
}
