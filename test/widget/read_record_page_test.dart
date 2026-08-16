import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:legado_flutter/application/platform/clipboard_port.dart';
import 'package:legado_flutter/features/my/read_record_page.dart';

class _FakeClipboard implements ClipboardPort {
  @override
  Future<void> copyText(String text) async {}

  @override
  Future<String?> pasteText() async => null;
}

void main() {
  testWidgets('ReadRecordPage shows fallback when engine unavailable', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Provider<ClipboardPort>.value(
        value: _FakeClipboard(),
        child: const MaterialApp(home: ReadRecordPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Rust 引擎或数据库未就绪'), findsOneWidget);
    expect(find.text('打开 LegadoRecord'), findsOneWidget);
  });
}
