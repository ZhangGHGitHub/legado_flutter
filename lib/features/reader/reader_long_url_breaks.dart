/// Source-preserving layout support for long URLs.
///
/// Flutter's paragraph breaker may keep a long URL as one unbreakable word.
/// The original reader can split measured URL text across lines. This helper
/// adds zero-width break opportunities only to a layout copy and keeps a
/// boundary map back to the original Dart string offsets.
abstract final class ReaderLongUrlBreaks {
  static const zeroWidthBreak = '\u200B';
  static const zeroWidthNoBreak = '\u2060';

  static final _urlPattern = RegExp(
    r'''(?:https?|ftp)://(?:\[[0-9A-Fa-f:.]+\]|[^\s<>\uFFFC，。！？；：、」』】）“”‘’（《【\u3000\u3001\u3002"'()\[\]{}]+)+''',
    caseSensitive: false,
  );

  static const _lineStartForbidden = <String>{
    '，',
    '。',
    '：',
    '？',
    '！',
    '、',
    '”',
    '’',
    '）',
    '》',
    '】',
    ')',
    '>',
    ']',
    '}',
    ',',
    '.',
    '?',
    '!',
    ':',
    ';',
  };

  static const _lineEndForbidden = <String>{
    '“',
    '（',
    '《',
    '【',
    '‘',
    '(',
    '<',
    '[',
    '{',
  };

  /// Creates a layout copy and an exact layout-boundary to source-boundary
  /// map. `minLength` avoids changing short URLs where Flutter already agrees
  /// with the original layout.
  static ReaderLongUrlLayout prepare(
    String source, {
    int minLength = 40,
    Iterable<ReaderLongUrlProtectedRange> protectedRanges = const [],
  }) {
    final protected = [
      for (final range in protectedRanges)
        if (range.start >= 0 &&
            range.end >= range.start &&
            range.end <= source.length)
          range,
    ];
    final insertions = <int, String>{};
    for (final match in _urlPattern.allMatches(source)) {
      var start = match.start;
      var end = match.end;
      while (end > start && _trailingPunctuation.contains(source[end - 1])) {
        end--;
      }
      if (end - start < 16) continue;
      if (_overlapsProtected(start, end, protected)) {
        continue;
      }

      // Work in Unicode scalar boundaries so a surrogate pair is never split.
      final boundaries = <int>[];
      var offset = start;
      while (offset < end) {
        final codeUnit = source.codeUnitAt(offset);
        final width =
            codeUnit >= 0xD800 &&
                codeUnit <= 0xDBFF &&
                offset + 1 < end &&
                source.codeUnitAt(offset + 1) >= 0xDC00 &&
                source.codeUnitAt(offset + 1) <= 0xDFFF
            ? 2
            : 1;
        offset += width;
        if (offset < end) boundaries.add(offset);
      }
      final naturalBoundaries = [
        for (final boundary in boundaries)
          if (_urlBreakAfter.contains(
            source.substring(
              _previousScalarStart(source, start, boundary),
              boundary,
            ),
          ))
            boundary,
      ];
      bool canBreakAt(int boundary) {
        final previous = source.substring(
          _previousScalarStart(source, start, boundary),
          boundary,
        );
        final next = source.substring(
          boundary,
          _nextScalarEnd(source, boundary),
        );
        return previous.isNotEmpty &&
            next.isNotEmpty &&
            !_lineEndForbidden.contains(previous) &&
            !_lineStartForbidden.contains(next);
      }

      // Prefer URL delimiters, but retain a safe scalar-boundary fallback if
      // punctuation rules reject every natural delimiter.
      final allowedNaturalBoundaries = [
        for (final boundary in naturalBoundaries)
          if (canBreakAt(boundary)) boundary,
      ];
      final breakBoundaries = end - start >= minLength
          ? (allowedNaturalBoundaries.isNotEmpty
                ? allowedNaturalBoundaries
                : [
                    for (final boundary in boundaries)
                      if (canBreakAt(boundary)) boundary,
                  ])
          : const <int>[];
      final breakBoundarySet = breakBoundaries.toSet();
      for (final boundary in boundaries) {
        final previous = source.substring(
          _previousScalarStart(source, start, boundary),
          boundary,
        );
        final next = source.substring(
          boundary,
          _nextScalarEnd(source, boundary),
        );
        if (previous.isEmpty || next.isEmpty) continue;
        final canBreak = breakBoundarySet.contains(boundary);
        insertions[boundary] = canBreak ? zeroWidthBreak : zeroWidthNoBreak;
      }
      // A break immediately before punctuation following a URL would move
      // that punctuation to a line start, so do not add a boundary at `end`.
    }

    final layout = StringBuffer();
    final layoutToSource = <int>[0];
    final insertedLayoutOffsets = <int>{};
    var sourceOffset = 0;
    for (var i = 0; i < source.length;) {
      final marker = insertions[i];
      if (marker != null) {
        if (marker == zeroWidthBreak) {
          insertedLayoutOffsets.add(layout.length);
        }
        layout.write(marker);
        layoutToSource.add(sourceOffset);
      }
      final width = _scalarWidth(source, i);
      layout.write(source.substring(i, i + width));
      i += width;
      sourceOffset = i;
      for (var boundary = 1; boundary <= width; boundary++) {
        layoutToSource.add(
          boundary == width ? sourceOffset : sourceOffset - width,
        );
      }
    }
    final terminalMarker = insertions[source.length];
    if (terminalMarker != null) {
      if (terminalMarker == zeroWidthBreak) {
        insertedLayoutOffsets.add(layout.length);
      }
      layout.write(terminalMarker);
      layoutToSource.add(source.length);
    }
    return ReaderLongUrlLayout(
      sourceText: source,
      layoutText: layout.toString(),
      layoutToSourceBoundary: layoutToSource,
      insertedLayoutOffsets: insertedLayoutOffsets,
    );
  }

  static const _trailingPunctuation = <String>{
    '，',
    '。',
    '；',
    '：',
    '！',
    '？',
    '、',
    '」',
    '』',
    '】',
    '）',
    ')',
    ']',
    '}',
    '"',
    "'",
    ',',
    '.',
    ';',
    ':',
    '!',
    '?',
  };

  static const _urlBreakAfter = <String>{
    '/',
    '?',
    '&',
    '=',
    '#',
    '%',
    '_',
    '-',
    '.',
  };

  static bool _overlapsProtected(
    int start,
    int end,
    List<ReaderLongUrlProtectedRange> ranges,
  ) => ranges.any((range) => start < range.end && range.start < end);

  static int _scalarWidth(String text, int offset) {
    if (offset + 1 < text.length) {
      final high = text.codeUnitAt(offset);
      final low = text.codeUnitAt(offset + 1);
      if (high >= 0xD800 && high <= 0xDBFF && low >= 0xDC00 && low <= 0xDFFF) {
        return 2;
      }
    }
    return 1;
  }

  static int _previousScalarStart(String text, int rangeStart, int boundary) {
    if (boundary - 2 >= rangeStart) {
      final high = text.codeUnitAt(boundary - 2);
      final low = text.codeUnitAt(boundary - 1);
      if (high >= 0xD800 && high <= 0xDBFF && low >= 0xDC00 && low <= 0xDFFF) {
        return boundary - 2;
      }
    }
    return boundary - 1;
  }

  static int _nextScalarEnd(String text, int boundary) =>
      boundary + _scalarWidth(text, boundary);
}

class ReaderLongUrlProtectedRange {
  final int start;
  final int end;

  const ReaderLongUrlProtectedRange(this.start, this.end);
}

class ReaderLongUrlLayout {
  final String sourceText;
  final String layoutText;
  final List<int> layoutToSourceBoundary;
  final Set<int> insertedLayoutOffsets;

  const ReaderLongUrlLayout({
    required this.sourceText,
    required this.layoutText,
    required this.layoutToSourceBoundary,
    required this.insertedLayoutOffsets,
  });

  int sourceOffsetForLayoutBoundary(int layoutOffset) {
    if (layoutOffset < 0 || layoutOffset >= layoutToSourceBoundary.length) {
      throw RangeError.range(
        layoutOffset,
        0,
        layoutToSourceBoundary.length - 1,
        'layoutOffset',
      );
    }
    return layoutToSourceBoundary[layoutOffset];
  }

  int layoutOffsetForSourceBoundary(int sourceOffset, {bool end = false}) {
    if (sourceOffset < 0 || sourceOffset > sourceText.length) {
      throw RangeError.range(
        sourceOffset,
        0,
        sourceText.length,
        'sourceOffset',
      );
    }
    final matches = <int>[];
    for (var i = 0; i < layoutToSourceBoundary.length; i++) {
      if (layoutToSourceBoundary[i] == sourceOffset) matches.add(i);
    }
    if (matches.isEmpty) {
      throw StateError('source boundary $sourceOffset is not mapped');
    }
    return end ? matches.last : matches.first;
  }

  ({int start, int end}) sourceRangeForLayoutRange(int start, int end) {
    if (start < 0 || end < start || end > layoutText.length) {
      throw RangeError('invalid layout range $start..$end');
    }
    return (
      start: sourceOffsetForLayoutBoundary(start),
      end: sourceOffsetForLayoutBoundary(end),
    );
  }

  String sourceTextForLayoutRange(int start, int end) {
    final range = sourceRangeForLayoutRange(start, end);
    return sourceText.substring(range.start, range.end);
  }

  bool isInsertedBreakAt(int layoutOffset) =>
      insertedLayoutOffsets.contains(layoutOffset);
}
