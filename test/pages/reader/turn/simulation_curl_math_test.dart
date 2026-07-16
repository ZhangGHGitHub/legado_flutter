import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/pages/reader/turn/simulation_curl_math.dart';

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
}
