import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:legado_flutter/application/reader/reader_font_port.dart';
import 'package:legado_flutter/application/rss/rss_source_transfer_port.dart';
import '../helpers/fake_reader_font_port.dart';
import 'package:legado_flutter/features/rss/rss_source_manage_page.dart';
import 'package:legado_flutter/providers/rss_provider.dart';

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
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => RssProvider(),
        child: Provider<ReaderFontPort>.value(
          value: _FakeReaderFontPort(),
          child: MaterialApp(home: RssSourceManagePage(transfer: transfer)),
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
}
