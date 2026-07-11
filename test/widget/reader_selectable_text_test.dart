import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/widgets/reader_selectable_text.dart';

void main() {
  testWidgets('ReaderSelectableText renders content', (tester) async {
    var captured = '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReaderSelectableText(
            text: '测试正文内容',
            style: const TextStyle(fontSize: 16),
            onWriteNote: (s) => captured = s,
          ),
        ),
      ),
    );

    expect(find.text('测试正文内容'), findsOneWidget);
    expect(captured, isEmpty);
  });
}
