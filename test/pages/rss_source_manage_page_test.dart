import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:legado_flutter/application/reader/reader_font_port.dart';
import 'package:legado_flutter/application/rss/rss_controller.dart';
import 'package:legado_flutter/application/rss/rss_notifier.dart';
import 'package:legado_flutter/application/rss/rss_source_transfer_port.dart';
import 'package:legado_flutter/domain/rss/rss_source.dart';
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

  testWidgets(
    'RssSourceManagePage keeps unsupported RSS actions behind explicit gates',
    (tester) async {
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

      await tester.tap(find.byTooltip('分组'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('分组管理'));
      await tester.pumpAndSettle();
      expect(find.text('「分组管理」暂未实现'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));

      const gatedOverflowActions = {'导入默认规则': '「导入默认规则」暂未实现', '帮助': '「帮助」暂未实现'};
      for (final entry in gatedOverflowActions.entries) {
        await tester.tap(find.byTooltip('更多'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(entry.key));
        await tester.pumpAndSettle();

        expect(find.text(entry.value), findsOneWidget);
        await tester.pump(const Duration(seconds: 5));
      }
    },
  );
}
