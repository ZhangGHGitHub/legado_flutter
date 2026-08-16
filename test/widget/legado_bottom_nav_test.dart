import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/widgets/legado_bottom_nav.dart';

import '../helpers/fake_reader_font_port.dart';

void main() {
  testWidgets('uses the reader font port for CJK navigation labels', (
    WidgetTester tester,
  ) async {
    const fontPort = _FakeReaderFontPort();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: LegadoBottomNav(
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            fontPort: fontPort,
            destinations: const [
              LegadoBottomNavItem(icon: Icons.book, label: '书架'),
            ],
          ),
        ),
      ),
    );

    final label = tester.widget<Text>(find.text('书架'));
    expect(label.data, '书架');
    expect(label.style?.fontFamily, 'TestSans');
    expect(label.style?.fontFamilyFallback, ['TestCjk', 'sans-serif']);
  });
}

final class _FakeReaderFontPort extends FakeReaderFontPort {
  const _FakeReaderFontPort();

  @override
  String platformSansFamily() => 'TestSans';

  @override
  List<String> cjkFallbackFamilies() => const ['TestCjk', 'sans-serif'];
}
