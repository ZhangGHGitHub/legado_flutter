import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/widgets/reader_inline_image.dart';

void main() {
  test('classifies SVG bytes before selecting the rendering branch', () {
    final svg = Uint8List.fromList(
      utf8.encode(
        '<svg width="20" height="10" viewBox="0 0 20 10" '
        'xmlns="http://www.w3.org/2000/svg"><rect width="20" height="10" '
        'fill="red"/></svg>',
      ),
    );
    expect(ReaderInlineImage.isSvgBytes(svg), isTrue);
    expect(
      ReaderInlineImage.isSvgBytes(Uint8List.fromList(const [0, 1, 2, 3])),
      isFalse,
    );
  });
}
