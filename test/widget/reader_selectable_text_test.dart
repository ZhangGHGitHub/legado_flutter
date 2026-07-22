import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/widgets/reader_selectable_text.dart';
import 'package:legado_flutter/widgets/reader_inline_image.dart';

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

  testWidgets('ReaderInlineImage keeps bounds when decoding fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: ReaderInlineImage(
            source: 'fixture://broken-image',
            width: 48,
            height: 32,
            imageProvider: MemoryImage(Uint8List.fromList(const [0])),
          ),
        ),
      ),
    );
    await tester.pump();

    final error = find.byKey(const ValueKey('reader-inline-image-error'));
    expect(error, findsOneWidget);
    final bounds = find.byKey(
      const ValueKey('reader-inline-image-bounds'),
    );
    expect(tester.getSize(bounds), const Size(48, 32));
  });

}
