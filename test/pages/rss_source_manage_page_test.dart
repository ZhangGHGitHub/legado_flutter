import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:legado_flutter/application/reader/reader_font_port.dart';
import 'package:legado_flutter/application/rss/rss_controller.dart';
import 'package:legado_flutter/application/rss/rss_default_source_import_port.dart';
import 'package:legado_flutter/application/rss/rss_notifier.dart';
import 'package:legado_flutter/application/rss/rss_source_transfer_port.dart';
import 'package:legado_flutter/domain/rss/rss_source.dart';
import 'package:legado_flutter/infrastructure/rss/rss_source_group_management_port_adapter.dart';
import '../helpers/fake_reader_font_port.dart';
import 'package:legado_flutter/features/rss/rss_source_manage_page.dart';

class _FakeRssSourceTransfer implements RssSourceTransferPort {
  int pickCount = 0;

  @override
  Future<String?> pickImportText() async {
    pickCount++;
    return '[]';
  }

  @override
  Future<void> copyText(String text) async {}
}

class _FakeDefaultRssSourceImport implements RssDefaultSourceImportPort {
  int calls = 0;

  @override
  Future<bool> importDefaults() async {
    calls++;
    return true;
  }
}

class _FakeReaderFontPort extends FakeReaderFontPort {
  @override
  String platformSansFamily() => 'TestSans';

  @override
  List<String> cjkFallbackFamilies() => const ['TestCjk', 'sans-serif'];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('RssSourceManagePage uses injected transfer for local import', (
    tester,
  ) async {
    final transfer = _FakeRssSourceTransfer();
    final controller = RssSourceController();
    await tester.pumpWidget(
      Provider<ReaderFontPort>.value(
        value: _FakeReaderFontPort(),
        child: MaterialApp(
          home: RssSourceManagePage(controller: controller, transfer: transfer),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final searchField = tester.widget<TextField>(find.byType(TextField));
    expect(searchField.style?.fontFamily, 'TestSans');
    expect(searchField.style?.fontFamilyFallback, ['TestCjk', 'sans-serif']);

    await tester.tap(find.byTooltip('更多'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('本地导入'));
    await tester.pumpAndSettle();

    expect(transfer.pickCount, 1);
  });

  testWidgets('RssSourceManagePage reuses the parent RSS controller', (
    tester,
  ) async {
    final controller = RssSourceController();
    final transfer = _FakeRssSourceTransfer();
    await controller.upsertSource(
      const RssSource(sourceUrl: 'https://example.com/rss', sourceName: '示例订阅'),
    );

    await tester.pumpWidget(
      Provider<ReaderFontPort>.value(
        value: _FakeReaderFontPort(),
        child: riverpod.ProviderScope(
          overrides: [
            rssSourceControllerProvider.overrideWithValue(controller),
          ],
          child: MaterialApp(home: RssSourceManagePage(transfer: transfer)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('示例订阅'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('RssSourceManagePage supports RSS group management commands', (
    tester,
  ) async {
    final controller = RssSourceController();
    await controller.upsertSource(
      const RssSource(
        sourceUrl: 'https://example.com/rss',
        sourceName: '示例订阅',
        sourceGroup: '旧组',
      ),
    );
    final groupPort = RssSourceGroupManagementPortAdapter(controller);

    await tester.pumpWidget(
      Provider<ReaderFontPort>.value(
        value: _FakeReaderFontPort(),
        child: MaterialApp(
          home: RssSourceManagePage(
            controller: controller,
            transfer: _FakeRssSourceTransfer(),
            groupManagement: groupPort,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('分组'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('分组管理'));
    await tester.pumpAndSettle();
    expect(find.text('旧组'), findsOneWidget);

    await tester.tap(find.byTooltip('重命名'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '新组');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(controller.sources.single.sourceGroup, '新组');

    await tester.tap(find.byTooltip('删除分组'));
    await tester.pumpAndSettle();
    expect(controller.sources.single.sourceGroup, isEmpty);
    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'RssSourceManagePage imports default RSS sources through its port',
    (tester) async {
      final importer = _FakeDefaultRssSourceImport();
      await tester.pumpWidget(
        Provider<ReaderFontPort>.value(
          value: _FakeReaderFontPort(),
          child: MaterialApp(
            home: RssSourceManagePage(
              controller: RssSourceController(),
              transfer: _FakeRssSourceTransfer(),
              defaultSourceImport: importer,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('更多'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('导入默认规则'));
      await tester.pumpAndSettle();

      expect(importer.calls, 1);
      expect(find.text('导入成功'), findsOneWidget);
    },
  );

  testWidgets('RssSourceManagePage opens the original RSS help asset', (
    tester,
  ) async {
    await tester.pumpWidget(
      Provider<ReaderFontPort>.value(
        value: _FakeReaderFontPort(),
        child: MaterialApp(
          home: RssSourceManagePage(
            controller: RssSourceController(),
            transfer: _FakeRssSourceTransfer(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('更多'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('帮助'));
    await tester.pumpAndSettle();

    expect(find.text('订阅源管理帮助'), findsOneWidget);
    expect(find.text('• 订阅源可以通过规则订阅一些网络内容'), findsOneWidget);
    expect(find.text('◦ 启用所选'), findsOneWidget);
  });
}
