import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:legado_flutter/application/reader/reader_font_port.dart';
import 'package:legado_flutter/features/rss/rss_tab_page.dart';
import 'package:legado_flutter/infrastructure/reader/reader_font_port_adapter.dart';
import 'package:legado_flutter/domain/rss/rss_source.dart';
import 'package:legado_flutter/providers/rss_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  testWidgets('RssTabPage shows search bar and rule subscription tile', (
    tester,
  ) async {
    final provider = RssProvider();
    await provider.upsertSource(
      const RssSource(
        sourceUrl: 'https://example.com/rss',
        sourceName: '示例订阅',
        sourceGroup: '测试',
      ),
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          Provider<ReaderFontPort>.value(value: const ReaderFontPortAdapter()),
        ],
        child: const MaterialApp(home: RssTabPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('规则订阅'), findsOneWidget);
    expect(find.text('示例订阅'), findsOneWidget);
    expect(find.text('RSS 订阅即将推出'), findsNothing);
  });

  testWidgets('RssTabPage reflects updates from the shared controller', (
    tester,
  ) async {
    final provider = RssProvider();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          Provider<ReaderFontPort>.value(value: const ReaderFontPortAdapter()),
        ],
        child: const MaterialApp(home: RssTabPage()),
      ),
    );
    await tester.pumpAndSettle();

    await provider.upsertSource(
      const RssSource(
        sourceUrl: 'https://example.com/updated',
        sourceName: '动态订阅',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('动态订阅'), findsOneWidget);
  });
}
