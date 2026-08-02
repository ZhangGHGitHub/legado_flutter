import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:legado_flutter/application/rss/rss_controller.dart';
import 'package:legado_flutter/application/rss/rss_source_store_port.dart';
import 'package:legado_flutter/domain/rss/rss_source.dart';
import 'package:legado_flutter/features/rss/rss_source_edit_page.dart';
import 'package:legado_flutter/application/rss/rss_source_edit_port.dart';
import 'package:legado_flutter/providers/rss_provider.dart';

class _FakeRssSourceEditPort implements RssSourceEditPort {
  RssSource? saved;

  @override
  Future<void> save(RssSource source) async {
    saved = source;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('editor saves through the injected boundary', (tester) async {
    final editor = _FakeRssSourceEditPort();
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => RssProvider(),
        child: MaterialApp(home: RssSourceEditPage(editor: editor)),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), 'https://example.com');
    await tester.enterText(find.byType(TextField).at(1), 'Example RSS');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(editor.saved?.sourceUrl, 'https://example.com');
    expect(editor.saved?.sourceName, 'Example RSS');
  });

  testWidgets('editor saves through the shared Riverpod RSS controller', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final source = RssSource(
      sourceUrl: 'https://example.com/rss',
      sourceName: '旧名称',
      enabled: false,
      loginUrl: 'https://example.com/login',
      sortUrl: '分类::https://example.com/sort',
      raw: {'legacyOption': 'preserve'},
    );
    final controller = RssSourceController(sourceStore: _FakeRssSourceStore());
    final provider = RssProvider(controller: controller);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(home: RssSourceEditPage(source: source)),
      ),
    );

    expect(find.byTooltip('登录'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(1), '新名称');
    await tester.tap(find.byType(SwitchListTile).first);
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final saved = controller.sources.single;
    expect(saved.sourceName, '新名称');
    expect(saved.enabled, isTrue);
    expect(saved.sortUrl, '分类::https://example.com/sort');
    expect(saved.loginUrl, 'https://example.com/login');
    expect(saved.raw['legacyOption'], 'preserve');
  });
}

class _FakeRssSourceStore implements RssSourceStorePort {
  @override
  Future<List<RssSource>> load() async => const [];

  @override
  Future<void> save(List<RssSource> sources) async {}
}
