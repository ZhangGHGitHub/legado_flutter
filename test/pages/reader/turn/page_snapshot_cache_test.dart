import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/pages/reader/turn/page_snapshot_cache.dart';

Future<ui.Image> _solidImage(ui.Color color) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 2, 2),
    ui.Paint()..color = color,
  );
  return recorder.endRecording().toImage(2, 2);
}

void main() {
  test('refresh success populates display.cur', () async {
    final cache = PageSnapshotCache(
      capturer: (key, {pixelRatio}) async {
        return _solidImage(const ui.Color(0xFF0000FF));
      },
    );
    addTearDown(cache.invalidate);

    final ok = await cache.refresh(
      prevKey: GlobalKey(),
      curKey: GlobalKey(),
      nextKey: GlobalKey(),
      pixelRatio: 1,
      hasPrev: false,
      hasNext: false,
    );

    expect(ok, isTrue);
    expect(cache.hasCur, isTrue);
    expect(cache.display?.cur, isNotNull);
    expect(cache.display?.prev, isNull);
    expect(cache.display?.next, isNull);
  });

  test('failed refresh keeps previous display', () async {
    var calls = 0;
    ui.Image? firstCur;

    final cache = PageSnapshotCache(
      capturer: (key, {pixelRatio}) async {
        calls++;
        if (calls == 1) {
          firstCur = await _solidImage(const ui.Color(0xFF00FF00));
          return firstCur;
        }
        return null; // simulate capture failure
      },
    );
    addTearDown(cache.invalidate);

    final ok1 = await cache.refresh(
      prevKey: GlobalKey(),
      curKey: GlobalKey(),
      nextKey: GlobalKey(),
      pixelRatio: 1,
      hasPrev: false,
      hasNext: false,
    );
    expect(ok1, isTrue);
    expect(identical(cache.display?.cur, firstCur), isTrue);

    final ok2 = await cache.refresh(
      prevKey: GlobalKey(),
      curKey: GlobalKey(),
      nextKey: GlobalKey(),
      pixelRatio: 1,
      hasPrev: false,
      hasNext: false,
    );
    expect(ok2, isFalse);
    expect(identical(cache.display?.cur, firstCur), isTrue);
  });

  test('hasPrev capture failure does not wipe display', () async {
    var calls = 0;
    final cache = PageSnapshotCache(
      capturer: (key, {pixelRatio}) async {
        calls++;
        // 1st refresh: cur only (hasPrev false)
        if (calls == 1) {
          return _solidImage(const ui.Color(0xFF112233));
        }
        // 2nd refresh: cur ok, prev fails
        if (calls == 2) {
          return _solidImage(const ui.Color(0xFF445566));
        }
        return null;
      },
    );
    addTearDown(cache.invalidate);

    expect(
      await cache.refresh(
        prevKey: GlobalKey(),
        curKey: GlobalKey(),
        nextKey: GlobalKey(),
        pixelRatio: 1,
        hasPrev: false,
        hasNext: false,
      ),
      isTrue,
    );
    final kept = cache.display?.cur;
    expect(kept, isNotNull);

    expect(
      await cache.refresh(
        prevKey: GlobalKey(),
        curKey: GlobalKey(),
        nextKey: GlobalKey(),
        pixelRatio: 1,
        hasPrev: true,
        hasNext: false,
      ),
      isFalse,
    );
    expect(identical(cache.display?.cur, kept), isTrue);
  });
}
