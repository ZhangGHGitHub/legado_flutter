import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/pages/reader/turn/page_snapshot.dart';

void main() {
  testWidgets('captureBoundary 得到非空图像', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: RepaintBoundary(
        key: key,
        child: const SizedBox(
          width: 80,
          height: 120,
          child: ColoredBox(color: Colors.red),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final img = await captureBoundary(key, pixelRatio: 1.0);
    expect(img, isNotNull);
    expect(img!.width, greaterThan(0));
    img.dispose();
  });
}
