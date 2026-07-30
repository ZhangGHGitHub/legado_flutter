import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:legado_flutter/application/reader/reader_font_port.dart';
import 'package:legado_flutter/features/rss/widgets/rss_source_tile.dart';

class _FakeReaderFontPort implements ReaderFontPort {
  @override
  String platformSansFamily() => 'TestSans';

  @override
  List<String> cjkFallbackFamilies() => const ['TestCjk', 'sans-serif'];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('RssSourceTile uses the injected reader font port', (
    tester,
  ) async {
    await tester.pumpWidget(
      Provider<ReaderFontPort>.value(
        value: _FakeReaderFontPort(),
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 180,
              height: 180,
              child: RssSourceTile(name: '中文订阅源', icon: Icons.rss_feed),
            ),
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('中文订阅源'));
    expect(text.style?.fontFamily, 'TestSans');
    expect(text.style?.fontFamilyFallback, ['TestCjk', 'sans-serif']);
  });
}
