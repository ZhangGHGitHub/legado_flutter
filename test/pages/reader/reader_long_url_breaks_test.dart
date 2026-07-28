import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/features/reader/reader_long_url_breaks.dart';

void main() {
  test(
    'long URLs receive layout-only breaks with source offsets preserved',
    () {
      const source = '前文 https://example.com/a_very_long_path/章节?id=123 后文。';
      final prepared = ReaderLongUrlBreaks.prepare(source);

      expect(
        prepared.layoutText
            .replaceAll(ReaderLongUrlBreaks.zeroWidthBreak, '')
            .replaceAll(ReaderLongUrlBreaks.zeroWidthNoBreak, ''),
        source,
      );
      expect(prepared.insertedLayoutOffsets, isNotEmpty);
      for (final offset in prepared.insertedLayoutOffsets) {
        expect(prepared.layoutText[offset], ReaderLongUrlBreaks.zeroWidthBreak);
        expect(
          prepared.sourceOffsetForLayoutBoundary(offset),
          prepared.sourceOffsetForLayoutBoundary(offset + 1),
        );
      }
      final urlStart = source.indexOf('https://');
      final urlEnd = source.indexOf(' 后文');
      for (final offset in prepared.insertedLayoutOffsets) {
        final sourceOffset = prepared.sourceOffsetForLayoutBoundary(offset);
        expect(sourceOffset, greaterThan(urlStart));
        expect(sourceOffset, lessThan(urlEnd));
      }
    },
  );

  test(
    'URL breaks do not change image placeholders or newpage source ranges',
    () {
      const image = '\uFFFC';
      const marker = '[newpage]';
      const source = '$image\nhttps://example.com/a_very_long_path\n$marker\n尾';
      final markerStart = source.indexOf(marker);
      final prepared = ReaderLongUrlBreaks.prepare(
        source,
        protectedRanges: [
          const ReaderLongUrlProtectedRange(0, 1),
          ReaderLongUrlProtectedRange(markerStart, markerStart + marker.length),
        ],
      );

      expect(prepared.sourceTextForLayoutRange(0, 1), image);
      expect(prepared.layoutText.contains(marker), isTrue);
      final markerLayoutOffset = prepared.layoutText.indexOf(marker);
      expect(
        prepared.sourceRangeForLayoutRange(
          markerLayoutOffset,
          markerLayoutOffset + marker.length,
        ),
        (start: markerStart, end: markerStart + marker.length),
      );
      expect(
        prepared.layoutText.substring(
          markerLayoutOffset,
          markerLayoutOffset + marker.length,
        ),
        marker,
      );
      expect(
        prepared.layoutText
            .replaceAll(ReaderLongUrlBreaks.zeroWidthBreak, '')
            .replaceAll(ReaderLongUrlBreaks.zeroWidthNoBreak, ''),
        source,
      );
    },
  );

  test(
    'break suggestions keep Chinese forbidden punctuation out of line starts',
    () {
      const source = '前 https://example.com/abcdefghijk。后';
      final prepared = ReaderLongUrlBreaks.prepare(source);
      final urlEnd = source.indexOf('。');

      for (final offset in prepared.insertedLayoutOffsets) {
        final sourceOffset = prepared.sourceOffsetForLayoutBoundary(offset);
        expect(sourceOffset, isNot(urlEnd));
        expect(source[sourceOffset], isNot('。'));
      }
    },
  );

  test('short URLs remain unchanged when no compatibility break is needed', () {
    const source = 'https://a.b/c';
    final prepared = ReaderLongUrlBreaks.prepare(source);
    expect(prepared.layoutText, source);
    expect(prepared.insertedLayoutOffsets, isEmpty);
    expect(prepared.sourceTextForLayoutRange(0, source.length), source);
  });

  test('short URLs receive no control characters', () {
    const source = 'https://a.b/c';
    final prepared = ReaderLongUrlBreaks.prepare(source);

    expect(source.length, lessThan(16));
    expect(prepared.layoutText, source);
    expect(prepared.insertedLayoutOffsets, isEmpty);
  });

  test(
    'medium URLs prevent natural slash breaks without adding page breaks',
    () {
      const source = 'https://example.com/medium_path';
      final prepared = ReaderLongUrlBreaks.prepare(source);

      expect(source.length, lessThan(40));
      expect(prepared.insertedLayoutOffsets, isEmpty);
      expect(prepared.layoutText, isNot(source));
      expect(
        prepared.layoutText
            .replaceAll(ReaderLongUrlBreaks.zeroWidthBreak, '')
            .replaceAll(ReaderLongUrlBreaks.zeroWidthNoBreak, ''),
        source,
      );
    },
  );

  test('URL termination preserves adjacent quotes and brackets', () {
    const source =
        'https://example.com/a_very_long_path/with_many_segments"正文（下一句）';
    final prepared = ReaderLongUrlBreaks.prepare(source);
    final urlEnd = source.indexOf('"');

    expect(prepared.insertedLayoutOffsets, isNotEmpty);
    for (final offset in prepared.insertedLayoutOffsets) {
      expect(prepared.sourceOffsetForLayoutBoundary(offset), lessThan(urlEnd));
    }
    expect(
      prepared.layoutText
          .replaceAll(ReaderLongUrlBreaks.zeroWidthBreak, '')
          .replaceAll(ReaderLongUrlBreaks.zeroWidthNoBreak, ''),
      source,
    );
  });

  test('IPv6 URL authorities are eligible for long URL breaks', () {
    const source = 'https://[2001:db8::1]/a_very_long_path/with_many_segments';
    final prepared = ReaderLongUrlBreaks.prepare(source);

    expect(prepared.insertedLayoutOffsets, isNotEmpty);
    expect(
      prepared.layoutText
          .replaceAll(ReaderLongUrlBreaks.zeroWidthBreak, '')
          .replaceAll(ReaderLongUrlBreaks.zeroWidthNoBreak, ''),
      source,
    );
    expect(prepared.layoutText.indexOf('['), greaterThanOrEqualTo(0));
  });

  test(
    'fallback breaks remain on scalar boundaries after supplementary text',
    () {
      const source =
          '前😀 https://example.com/a_very_long_path/with_many_segments?id=123';
      final prepared = ReaderLongUrlBreaks.prepare(source);
      final urlStart = source.indexOf('https://');
      final urlEnd = source.length;

      for (final offset in prepared.insertedLayoutOffsets) {
        final sourceOffset = prepared.sourceOffsetForLayoutBoundary(offset);
        expect(sourceOffset, greaterThan(urlStart));
        expect(sourceOffset, lessThan(urlEnd));
        expect(
          sourceOffset == 0 ||
              source.codeUnitAt(sourceOffset - 1) < 0xDC00 ||
              source.codeUnitAt(sourceOffset - 1) > 0xDFFF,
          isTrue,
        );
      }
      expect(
        prepared.sourceTextForLayoutRange(0, prepared.layoutText.length),
        source,
      );
    },
  );

  test(
    'TextPainter can break the layout copy and map lines to source ranges',
    () {
      const source =
          '前 https://example.com/a_very_long_path/with_many_segments?id=123456789 后';
      final prepared = ReaderLongUrlBreaks.prepare(source);
      final painter = TextPainter(
        text: TextSpan(
          text: prepared.layoutText,
          style: const TextStyle(fontSize: 16),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 90);

      final sourceRanges = <({int start, int end})>[];
      for (final metric in painter.computeLineMetrics()) {
        final position = painter.getPositionForOffset(
          Offset(0, metric.baseline),
        );
        final line = painter.getLineBoundary(position);
        if (!line.isValid || line.start == line.end) continue;
        sourceRanges.add(
          prepared.sourceRangeForLayoutRange(line.start, line.end),
        );
      }

      expect(sourceRanges.length, greaterThan(1));
      expect(sourceRanges.first.start, 0);
      for (var i = 1; i < sourceRanges.length; i++) {
        expect(sourceRanges[i].start, sourceRanges[i - 1].end);
      }
      expect(sourceRanges.last.end, source.length);
      expect(
        sourceRanges
            .map((range) => source.substring(range.start, range.end))
            .join(),
        source,
      );
    },
  );

  test(
    'source mapping keeps UTF-16 boundaries after a supplementary scalar',
    () {
      const source =
          '前😀 https://example.com/a_very_long_path/with_many_segments?id=123';
      final prepared = ReaderLongUrlBreaks.prepare(source);

      expect(
        prepared.sourceTextForLayoutRange(0, prepared.layoutText.length),
        source,
      );
      expect(
        prepared.sourceRangeForLayoutRange(0, prepared.layoutText.length),
        (start: 0, end: source.length),
      );
    },
  );
}
