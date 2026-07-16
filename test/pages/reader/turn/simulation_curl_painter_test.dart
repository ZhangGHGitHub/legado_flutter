import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/pages/reader/turn/page_direction.dart';
import 'package:legado_flutter/pages/reader/turn/painters/simulation_curl_painter.dart';
import 'package:legado_flutter/pages/reader/turn/simulation_curl_math.dart';

Future<ui.Image> _createTestImage(Color color) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 1, 1),
    Paint()..color = color,
  );
  final picture = recorder.endRecording();
  return picture.toImage(1, 1);
}

void main() {
  testWidgets('SimulationCurlPainter idle does not crash', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CustomPaint(
          size: const Size(200, 300),
          painter: SimulationCurlPainter(
            cur: null,
            prev: null,
            next: null,
            direction: PageTurnDirection.none,
            touchX: 0,
            touchY: 0,
            cornerX: 200,
            cornerY: 300,
            viewSize: const Size(200, 300),
            isRunning: false,
          ),
        ),
      ),
    );
    await tester.pump();
  });

  testWidgets('SimulationCurlPainter next curl does not crash', (tester) async {
    final cur = await _createTestImage(Colors.blue);
    final next = await _createTestImage(Colors.green);
    addTearDown(cur.dispose);
    addTearDown(next.dispose);

    const view = Size(200, 300);
    final corner = calcCornerXY(
      x: 150,
      y: 250,
      viewWidth: view.width,
      viewHeight: view.height,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CustomPaint(
          size: view,
          painter: SimulationCurlPainter(
            cur: cur,
            prev: null,
            next: next,
            direction: PageTurnDirection.next,
            touchX: 120,
            touchY: 220,
            cornerX: corner.cornerX,
            cornerY: corner.cornerY,
            viewSize: view,
            isRunning: true,
          ),
        ),
      ),
    );
    await tester.pump();
  });
}
