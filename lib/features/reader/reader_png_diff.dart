import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Compares two PNG images without depending on Flutter rendering APIs.
class ReaderPngDiff {
  ReaderPngDiff._();

  /// Compares [expectedPng] and [actualPng] as RGBA images.
  ///
  /// A pixel is different when at least one of its four channel differences
  /// is greater than the configured tolerance. Channel statistics always use
  /// the raw absolute differences, including channels within the tolerance.
  static ReaderPngDiffResult compare(
    List<int> expectedPng,
    List<int> actualPng, {
    int channelTolerance = 0,
    int? tolerance,
  }) {
    final effectiveTolerance = tolerance ?? channelTolerance;
    if (effectiveTolerance < 0 || effectiveTolerance > 255) {
      throw ArgumentError.value(
        effectiveTolerance,
        'channelTolerance',
        'must be between 0 and 255',
      );
    }

    final expected = _decodeRgba(expectedPng, 'expectedPng');
    final actual = _decodeRgba(actualPng, 'actualPng');
    final dimensionsMatch =
        expected.width == actual.width && expected.height == actual.height;

    if (!dimensionsMatch) {
      return ReaderPngDiffResult(
        expectedWidth: expected.width,
        expectedHeight: expected.height,
        actualWidth: actual.width,
        actualHeight: actual.height,
        dimensionsMatch: false,
        differingPixelCount: 0,
        pixelCount: 0,
        differingPixelRatio: 0,
        maxChannelDifference: 0,
        averageChannelDifference: 0,
        differenceBounds: null,
      );
    }

    final pixelCount = expected.width * expected.height;
    final expectedBytes = expected.rgba;
    final actualBytes = actual.rgba;
    var differingPixelCount = 0;
    var totalChannelDifference = 0;
    var maxChannelDifference = 0;
    int? left;
    int? top;
    int? right;
    int? bottom;

    for (var y = 0; y < expected.height; y++) {
      for (var x = 0; x < expected.width; x++) {
        final offset = (y * expected.width + x) * 4;
        var pixelDiffers = false;
        for (var channel = 0; channel < 4; channel++) {
          final difference =
              (expectedBytes[offset + channel] - actualBytes[offset + channel])
                  .abs();
          totalChannelDifference += difference;
          if (difference > maxChannelDifference) {
            maxChannelDifference = difference;
          }
          if (difference > effectiveTolerance) {
            pixelDiffers = true;
          }
        }

        if (!pixelDiffers) continue;
        differingPixelCount++;
        left = left == null || x < left ? x : left;
        top = top == null || y < top ? y : top;
        right = right == null || x > right ? x : right;
        bottom = bottom == null || y > bottom ? y : bottom;
      }
    }

    return ReaderPngDiffResult(
      expectedWidth: expected.width,
      expectedHeight: expected.height,
      actualWidth: actual.width,
      actualHeight: actual.height,
      dimensionsMatch: true,
      differingPixelCount: differingPixelCount,
      pixelCount: pixelCount,
      differingPixelRatio: pixelCount == 0
          ? 0
          : differingPixelCount / pixelCount,
      maxChannelDifference: maxChannelDifference,
      averageChannelDifference: pixelCount == 0
          ? 0
          : totalChannelDifference / (pixelCount * 4),
      differenceBounds: left == null
          ? null
          : ReaderPngDiffBounds(
              left: left,
              top: top!,
              right: right!,
              bottom: bottom!,
            ),
    );
  }

  /// Alias that reads naturally at call sites handling PNG-specific input.
  static ReaderPngDiffResult comparePng(
    List<int> expectedPng,
    List<int> actualPng, {
    int channelTolerance = 0,
    int? tolerance,
  }) {
    return compare(
      expectedPng,
      actualPng,
      channelTolerance: channelTolerance,
      tolerance: tolerance,
    );
  }
}

class _DecodedRgba {
  final int width;
  final int height;
  final Uint8List rgba;

  const _DecodedRgba(this.width, this.height, this.rgba);
}

_DecodedRgba _decodeRgba(List<int> bytes, String name) {
  try {
    final decoded = img.decodePng(Uint8List.fromList(bytes));
    if (decoded == null) {
      throw const FormatException('not a PNG image');
    }
    final rgba = decoded
        .convert(numChannels: 4)
        .getBytes(order: img.ChannelOrder.rgba);
    return _DecodedRgba(decoded.width, decoded.height, rgba);
  } on FormatException catch (error) {
    throw FormatException('Unable to decode $name: ${error.message}');
  } catch (error) {
    throw FormatException('Unable to decode $name: $error');
  }
}

/// Inclusive pixel coordinates containing every pixel outside the tolerance.
class ReaderPngDiffBounds {
  final int left;
  final int top;
  final int right;
  final int bottom;

  const ReaderPngDiffBounds({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  int get width => right - left + 1;

  int get height => bottom - top + 1;

  int get xMin => left;

  int get yMin => top;

  int get xMax => right;

  int get yMax => bottom;

  @override
  bool operator ==(Object other) {
    return other is ReaderPngDiffBounds &&
        other.left == left &&
        other.top == top &&
        other.right == right &&
        other.bottom == bottom;
  }

  @override
  int get hashCode => Object.hash(left, top, right, bottom);

  @override
  String toString() => '($left, $top)..($right, $bottom)';
}

typedef ReaderPngDiffBoundingBox = ReaderPngDiffBounds;

/// Measurements produced by [ReaderPngDiff.compare].
class ReaderPngDiffResult {
  final int expectedWidth;
  final int expectedHeight;
  final int actualWidth;
  final int actualHeight;
  final bool dimensionsMatch;
  final int differingPixelCount;
  final int pixelCount;
  final double differingPixelRatio;
  final int maxChannelDifference;
  final double averageChannelDifference;
  final ReaderPngDiffBounds? differenceBounds;

  const ReaderPngDiffResult({
    required this.expectedWidth,
    required this.expectedHeight,
    required this.actualWidth,
    required this.actualHeight,
    required this.dimensionsMatch,
    required this.differingPixelCount,
    required this.pixelCount,
    required this.differingPixelRatio,
    required this.maxChannelDifference,
    required this.averageChannelDifference,
    required this.differenceBounds,
  });

  bool get isMatch => dimensionsMatch && differingPixelCount == 0;

  bool get isSameSize => dimensionsMatch;

  bool get hasDifferences => differingPixelCount != 0;

  int get differencePixelCount => differingPixelCount;

  double get differencePixelRatio => differingPixelRatio;

  int get maxChannelDiff => maxChannelDifference;

  double get averageChannelDiff => averageChannelDifference;

  ReaderPngDiffBounds? get boundingBox => differenceBounds;
}
