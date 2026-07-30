import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:legado_flutter/application/reader/reader_font_port.dart';
import '../../helpers/fake_reader_font_port.dart';
import 'package:legado_flutter/features/bookshelf/bookshelf_overflow_menu.dart';

class _FakeReaderFontPort extends FakeReaderFontPort {
  @override
  String platformSansFamily() => 'Test Sans';

  @override
  List<String> cjkFallbackFamilies() => const [
    'CJK Primary',
    'CJK Secondary',
    'sans-serif',
  ];
}

void main() {
  Future<void> pumpMenu(WidgetTester tester) async {
    await tester.pumpWidget(
      Provider<ReaderFontPort>.value(
        value: _FakeReaderFontPort(),
        child: MaterialApp(
          home: Scaffold(
            body: PopupMenuButton<String>(
              itemBuilder: BookshelfOverflowMenu.items,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
  }

  testWidgets('menu uses the injected reader font contract', (tester) async {
    await pumpMenu(tester);

    final label = tester.widget<Text>(find.text('更新目录'));
    expect(label.style?.fontFamily, 'Test Sans');
    expect(label.style?.fontFamilyFallback, [
      'CJK Primary',
      'CJK Secondary',
      'sans-serif',
    ]);
  });

  testWidgets('menu keeps the established action order and labels', (
    tester,
  ) async {
    await pumpMenu(tester);

    final values = tester
        .widgetList<PopupMenuItem<String>>(find.byType(PopupMenuItem<String>))
        .map((item) => item.value)
        .toList();
    expect(values, [
      BookshelfOverflowMenu.updateToc,
      BookshelfOverflowMenu.addLocal,
      BookshelfOverflowMenu.remoteBook,
      BookshelfOverflowMenu.addUrl,
      BookshelfOverflowMenu.arrange,
      BookshelfOverflowMenu.cacheExport,
      BookshelfOverflowMenu.groupMgmt,
      BookshelfOverflowMenu.layout,
      BookshelfOverflowMenu.exportList,
      BookshelfOverflowMenu.importList,
      BookshelfOverflowMenu.log,
    ]);
    expect(find.text('添加网址'), findsOneWidget);
    expect(find.text('导出书单'), findsOneWidget);
    expect(find.text('导入书单'), findsOneWidget);
    expect(find.text('日志'), findsOneWidget);
  });
}
