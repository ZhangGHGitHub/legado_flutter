import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/features/reader/turn/page_direction.dart';
import 'package:legado_flutter/features/reader/turn/painters/cover_page_painter.dart';
import 'package:legado_flutter/features/reader/turn/painters/slide_page_painter.dart';

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
  group('SlidePagePainter', () {
    testWidgets('direction none with null images does not crash', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CustomPaint(
            size: const Size(200, 300),
            painter: SlidePagePainter(
              cur: null,
              prev: null,
              next: null,
              direction: PageTurnDirection.none,
              touchX: 0,
              startX: 0,
              viewSize: const Size(200, 300),
              isRunning: false,
            ),
          ),
        ),
      );
      await tester.pump();
    });

    testWidgets('next turn with images does not crash', (tester) async {
      final cur = await _createTestImage(Colors.blue);
      final next = await _createTestImage(Colors.green);
      addTearDown(cur.dispose);
      addTearDown(next.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: CustomPaint(
            size: const Size(200, 300),
            painter: SlidePagePainter(
              cur: cur,
              prev: null,
              next: next,
              direction: PageTurnDirection.next,
              touchX: 120,
              startX: 200,
              viewSize: const Size(200, 300),
              isRunning: true,
            ),
          ),
        ),
      );
      await tester.pump();
    });
  });

  group('CoverPagePainter', () {
    testWidgets('direction none with null images does not crash', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CustomPaint(
            size: const Size(200, 300),
            painter: CoverPagePainter(
              cur: null,
              prev: null,
              next: null,
              direction: PageTurnDirection.none,
              touchX: 0,
              startX: 0,
              viewSize: const Size(200, 300),
              isRunning: false,
            ),
          ),
        ),
      );
      await tester.pump();
    });

    testWidgets('prev turn with images does not crash', (tester) async {
      final cur = await _createTestImage(Colors.blue);
      final prev = await _createTestImage(Colors.orange);
      addTearDown(cur.dispose);
      addTearDown(prev.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: CustomPaint(
            size: const Size(200, 300),
            painter: CoverPagePainter(
              cur: cur,
              prev: prev,
              next: null,
              direction: PageTurnDirection.prev,
              touchX: 180,
              startX: 100,
              viewSize: const Size(200, 300),
              isRunning: true,
            ),
          ),
        ),
      );
      await tester.pump();
    });
  });
}
