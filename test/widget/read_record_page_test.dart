import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/features/my/read_record_page.dart';

void main() {
  testWidgets('ReadRecordPage shows fallback when engine unavailable', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ReadRecordPage()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Rust 引擎或数据库未就绪'), findsOneWidget);
    expect(find.text('打开 LegadoRecord'), findsOneWidget);
  });
}
