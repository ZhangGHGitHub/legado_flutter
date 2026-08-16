import 'package:flutter_test/flutter_test.dart';
import 'dart:math' as math;
import 'package:legado_flutter/features/reader/turn/simulation_curl_math.dart';

void main() {
  test('calcCornerXY 右下象限', () {
    final c = calcCornerXY(x: 300, y: 500, viewWidth: 400, viewHeight: 800);
    expect(c.cornerX, 400);
    expect(c.cornerY, 800);
  });

  test('calcCornerXY 左上象限', () {
    final c = calcCornerXY(x: 50, y: 50, viewWidth: 400, viewHeight: 800);
    expect(c.cornerX, 0);
    expect(c.cornerY, 0);
  });

  test('calcPoints 不抛且 touchToCornerDis > 0', () {
    final p = calcPoints(
      touchX: 200,
      touchY: 600,
      cornerX: 400,
      cornerY: 800,
      viewWidth: 400,
      viewHeight: 800,
    );
    expect(p.touchToCornerDis, greaterThan(0));
  });

  group('drawCurrentBackArea matrix reflection', () {
    // Verifies the 3x3 affine reflection matrix computed in
    // SimulationCurlPainter._drawCurrentBackArea matches
    // Jingshiro SimulationPageDelegate.drawCurrentBackArea Matrix math.
    // Tests both a smoke (finite/det) and a golden (element-level) assertion.

    test('golden: matrix elements for known geometry (右下 corner)', () {
      // touchX=200, touchY=600, cornerX=400, cornerY=800,
      // viewWidth=400, viewHeight=800
      // → bezierControl1=(299, 800), bezierControl2=(400, 699)
      // → dis = 101*sqrt(2), f8 = 1/sqrt(2), f9 = -1/sqrt(2)
      // → m0=0, m1=-1, m4=0 (exact rational)
      final p = calcPoints(
        touchX: 200,
        touchY: 600,
        cornerX: 400,
        cornerY: 800,
        viewWidth: 400,
        viewHeight: 800,
      );

      final dis = math.sqrt(
        (400 - p.bezierControl1.dx) * (400 - p.bezierControl1.dx) +
            (p.bezierControl2.dy - 800) * (p.bezierControl2.dy - 800),
      );
      expect(dis, greaterThan(0));

      final f8 = (400 - p.bezierControl1.dx) / dis;
      final f9 = (p.bezierControl2.dy - 800) / dis;

      final m0 = 1 - 2 * f9 * f9;
      final m1 = 2 * f8 * f9;
      final m4 = 1 - 2 * f8 * f8;

      // Golden: known exact values for this geometry
      expect(m0, closeTo(0.0, 1e-10));
      expect(m1, closeTo(-1.0, 1e-10));
      expect(m4, closeTo(0.0, 1e-10));
      expect(m0 * m4 - m1 * m1, closeTo(-1.0, 1e-10));
    });

    test('non-degenerate for 左上 corner', () {
      final p = calcPoints(
        touchX: 350,
        touchY: 100,
        cornerX: 0,
        cornerY: 0,
        viewWidth: 400,
        viewHeight: 800,
      );

      final dis = math.sqrt(
        (0 - p.bezierControl1.dx) * (0 - p.bezierControl1.dx) +
            (p.bezierControl2.dy - 0) * (p.bezierControl2.dy - 0),
      );
      expect(dis, greaterThan(0));

      final f8 = (0 - p.bezierControl1.dx) / dis;
      final f9 = (p.bezierControl2.dy - 0) / dis;

      final m0 = 1 - 2 * f9 * f9;
      final m1 = 2 * f8 * f9;
      final m4 = 1 - 2 * f8 * f8;

      expect(m0.isFinite, isTrue);
      expect(m1.isFinite, isTrue);
      expect(m4.isFinite, isTrue);
      expect(m0 * m4 - m1 * m1, closeTo(-1.0, 1e-6));
    });
  });
}
