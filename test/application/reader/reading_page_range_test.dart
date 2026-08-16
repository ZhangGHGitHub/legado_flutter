import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/reader/reading_position_mapper.dart';

void main() {
  group('ReadingPageRange Freezed contract', () {
    test(
      'preserves UTF-16 half-open offsets independently of displayed text',
      () {
        const range = ReadingPageRange(text: 'A\n😀', start: 3, end: 5);

        expect(range.start, 3);
        expect(range.end, 5);
        expect(range.end - range.start, 2);
      },
    );

    test('keeps layout-only newlines out of source range identity', () {
      const sourceRange = ReadingPageRange(text: '甲乙', start: 0, end: 2);
      const displayedRange = ReadingPageRange(text: '甲\n乙', start: 0, end: 2);

      expect(sourceRange, isNot(displayedRange));
      expect(sourceRange.start, displayedRange.start);
      expect(sourceRange.end, displayedRange.end);
    });

    test(
      'supports immutable value copies without changing the original range',
      () {
        const original = ReadingPageRange(text: '😀', start: 6, end: 8);
        final displayed = original.copyWith(text: '😀\n');

        expect(
          displayed,
          const ReadingPageRange(text: '😀\n', start: 6, end: 8),
        );
        expect(original, const ReadingPageRange(text: '😀', start: 6, end: 8));
      },
    );
  });
}
