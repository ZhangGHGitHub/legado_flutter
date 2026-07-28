import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:legado_flutter/features/reader/reader_png_diff.dart';
import 'package:flutter_test/flutter_test.dart';

List<int> _png(int width, int height, Map<String, List<int>> pixels) {
  final image = img.Image(width: width, height: height, numChannels: 4);
  for (final entry in pixels.entries) {
    final coordinates = entry.key.split(',').map(int.parse).toList();
    final color = entry.value;
    image.setPixelRgba(
      coordinates[0],
      coordinates[1],
      color[0],
      color[1],
      color[2],
      color[3],
    );
  }
  return img.encodePng(image);
}

void main() {
  test('equal PNGs decode as RGBA and produce no differences', () {
    final png = _png(2, 1, {
      '0,0': [10, 20, 30, 40],
      '1,0': [240, 230, 220, 210],
    });

    final result = ReaderPngDiff.compare(png, png);

    expect(result.isMatch, isTrue);
    expect(result.dimensionsMatch, isTrue);
    expect(result.pixelCount, 2);
    expect(result.differingPixelCount, 0);
    expect(result.differingPixelRatio, 0);
    expect(result.maxChannelDifference, 0);
    expect(result.averageChannelDifference, 0);
    expect(result.differenceBounds, isNull);
  });

  test('uses per-channel tolerance and reports raw channel statistics', () {
    final expected = _png(3, 2, {
      '0,0': [100, 100, 100, 255],
      '1,0': [100, 100, 100, 255],
      '2,1': [100, 100, 100, 255],
    });
    final actual = _png(3, 2, {
      '0,0': [103, 100, 100, 255],
      '1,0': [110, 100, 100, 255],
      '2,1': [100, 100, 100, 250],
    });

    final result = ReaderPngDiff.compare(expected, actual, tolerance: 3);

    expect(result.isMatch, isFalse);
    expect(result.differingPixelCount, 2);
    expect(result.differingPixelRatio, closeTo(2 / 6, 0.000001));
    expect(result.maxChannelDifference, 10);
    expect(result.averageChannelDifference, closeTo(18 / 24, 0.000001));
    expect(
      result.differenceBounds,
      const ReaderPngDiffBounds(left: 1, top: 0, right: 2, bottom: 1),
    );
  });

  test('reports dimension mismatch without comparing unrelated pixels', () {
    final expected = _png(2, 1, const {});
    final actual = _png(3, 1, const {});

    final result = ReaderPngDiff.compare(expected, actual);

    expect(result.isMatch, isFalse);
    expect(result.dimensionsMatch, isFalse);
    expect(result.expectedWidth, 2);
    expect(result.actualWidth, 3);
    expect(result.pixelCount, 0);
    expect(result.differenceBounds, isNull);
  });

  test('rejects invalid PNG bytes and invalid tolerance', () {
    expect(
      () => ReaderPngDiff.compare(const [1, 2, 3], const [1, 2, 3]),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => ReaderPngDiff.compare(
        _png(1, 1, const {}),
        _png(1, 1, const {}),
        channelTolerance: 256,
      ),
      throwsArgumentError,
    );
  });

  test('fixed reader fixture passes the pixel gate', () {
    final expected = File(
      'test/fixtures/reader/module3/module3_original_fixed_001.png',
    ).readAsBytesSync();
    final actual = File(
      'test/fixtures/reader/module3/module3_rewrite_fixed_001.png',
    ).readAsBytesSync();

    final result = ReaderPngDiff.compare(expected, actual);
    expect(result.isMatch, isTrue);
    expect(result.differingPixelCount, 0);
    expect(result.differingPixelRatio, 0);
  });
}
