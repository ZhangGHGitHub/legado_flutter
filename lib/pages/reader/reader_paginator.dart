import 'package:flutter/widgets.dart';

/// A page slice with chapter-relative character offsets.
class ReaderPageSlice {
  final String text;
  final int start;
  final int end;

  const ReaderPageSlice({
    required this.text,
    required this.start,
    required this.end,
  });
}

/// A one-character inline placeholder with dimensions used by pagination.
class ReaderPaginatorPlaceholder {
  final int start;
  final int end;
  final double width;
  final double height;

  const ReaderPaginatorPlaceholder({
    required this.start,
    required this.end,
    required this.width,
    required this.height,
  });
}

/// Computes the displayed image bounds used by both pagination and widgets.
abstract final class ReaderImageLayout {
  static Size? displaySize({
    required Size natural,
    required double maxWidth,
    String style = 'DEFAULT',
    double? maxHeight,
    double? widthOverride,
  }) {
    if (natural.width <= 0 || natural.height <= 0 || maxWidth <= 0) {
      return null;
    }
    if (widthOverride != null && widthOverride <= 0) return null;
    final adjustedNatural = widthOverride == null
        ? natural
        : Size(widthOverride, natural.height * widthOverride / natural.width);
    final normalizedStyle = style.toUpperCase();
    final fillsWidth =
        (normalizedStyle == 'FULL' || normalizedStyle == 'SINGLE') &&
        maxWidth.isFinite;
    final width = fillsWidth
        ? maxWidth
        : maxWidth.isFinite && adjustedNatural.width > maxWidth
        ? maxWidth
        : adjustedNatural.width;
    var height = adjustedNatural.height * width / adjustedNatural.width;
    if (normalizedStyle == 'SINGLE' &&
        maxHeight != null &&
        maxHeight.isFinite &&
        maxHeight > 0 &&
        height > maxHeight) {
      height = maxHeight;
      return Size(width * maxHeight / height, height);
    }
    return Size(width, height);
  }

  static double? parseWidth(String? value, double maxWidth) {
    if (value == null || value.trim().isEmpty || maxWidth <= 0) return null;
    final text = value.trim();
    if (text.endsWith('%')) {
      final percentage = double.tryParse(text.substring(0, text.length - 1));
      if (percentage == null || percentage <= 0) return null;
      return maxWidth * percentage / 100;
    }
    final width = double.tryParse(text);
    return width != null && width > 0 ? width : null;
  }
}

/// Line-based paginator matching the original reader's TextPage layout model.
abstract final class ReaderPaginator {
  static final _hardPageBreakLine = RegExp(
    r'^\s*\[newpage\]\s*$',
    multiLine: true,
  );

  static List<ReaderPageSlice> paginate({
    required String text,
    required TextStyle style,
    required double maxWidth,
    required double maxHeight,
    TextAlign textAlign = TextAlign.start,

    /// Extra paragraph spacing in tenths of a line height, matching
    /// Legado's `paragraphSpacing / 10f` calculation.
    double paragraphSpacingTenths = 0,
    bool respectHardPageBreaks = true,
    List<ReaderPaginatorPlaceholder> placeholders = const [],
    bool singleImageStyle = false,
  }) {
    if (singleImageStyle && text.contains('\uFFFC')) {
      return _paginateSingleImageStyle(
        text: text,
        style: style,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        textAlign: textAlign,
        paragraphSpacingTenths: paragraphSpacingTenths,
        respectHardPageBreaks: respectHardPageBreaks,
        placeholders: placeholders,
      );
    }
    if (respectHardPageBreaks && _hardPageBreakLine.hasMatch(text)) {
      return _paginateWithHardPageBreaks(
        text: text,
        style: style,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        textAlign: textAlign,
        paragraphSpacingTenths: paragraphSpacingTenths,
        placeholders: placeholders,
      );
    }
    return _paginateText(
      text: text,
      style: style,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      textAlign: textAlign,
      paragraphSpacingTenths: paragraphSpacingTenths,
      placeholders: placeholders,
    );
  }

  /// The original SINGLE image style lays each image out as its own page.
  /// Text remains source-contiguous; only the page boundaries are virtual.
  static List<ReaderPageSlice> _paginateSingleImageStyle({
    required String text,
    required TextStyle style,
    required double maxWidth,
    required double maxHeight,
    required TextAlign textAlign,
    required double paragraphSpacingTenths,
    required bool respectHardPageBreaks,
    required List<ReaderPaginatorPlaceholder> placeholders,
  }) {
    final pages = <ReaderPageSlice>[];
    var segmentStart = 0;
    for (
      var imageStart = text.indexOf('\uFFFC');
      imageStart >= 0;
      imageStart = text.indexOf('\uFFFC', imageStart + 1)
    ) {
      _appendSingleImageSegment(
        pages: pages,
        text: text,
        start: segmentStart,
        end: imageStart,
        style: style,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        textAlign: textAlign,
        paragraphSpacingTenths: paragraphSpacingTenths,
        respectHardPageBreaks: respectHardPageBreaks,
        placeholders: placeholders,
      );
      pages.add(
        ReaderPageSlice(
          text: text.substring(imageStart, imageStart + 1),
          start: imageStart,
          end: imageStart + 1,
        ),
      );
      segmentStart = imageStart + 1;
    }
    _appendSingleImageSegment(
      pages: pages,
      text: text,
      start: segmentStart,
      end: text.length,
      style: style,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      textAlign: textAlign,
      paragraphSpacingTenths: paragraphSpacingTenths,
      respectHardPageBreaks: respectHardPageBreaks,
      placeholders: placeholders,
    );
    return pages.isEmpty
        ? [ReaderPageSlice(text: text, start: 0, end: text.length)]
        : pages;
  }

  static void _appendSingleImageSegment({
    required List<ReaderPageSlice> pages,
    required String text,
    required int start,
    required int end,
    required TextStyle style,
    required double maxWidth,
    required double maxHeight,
    required TextAlign textAlign,
    required double paragraphSpacingTenths,
    required bool respectHardPageBreaks,
    required List<ReaderPaginatorPlaceholder> placeholders,
  }) {
    if (start >= end) return;
    final segment = text.substring(start, end);
    final segmentPlaceholders = [
      for (final placeholder in placeholders)
        if (placeholder.start >= start && placeholder.end <= end)
          ReaderPaginatorPlaceholder(
            start: placeholder.start - start,
            end: placeholder.end - start,
            width: placeholder.width,
            height: placeholder.height,
          ),
    ];
    for (final page in paginate(
      text: segment,
      style: style,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      textAlign: textAlign,
      paragraphSpacingTenths: paragraphSpacingTenths,
      respectHardPageBreaks: respectHardPageBreaks,
      placeholders: segmentPlaceholders,
    )) {
      pages.add(
        ReaderPageSlice(
          text: page.text,
          start: start + page.start,
          end: start + page.end,
        ),
      );
    }
  }

  /// Maps a chapter-relative source position to the page containing it.
  /// Positions skipped by a hard page marker resolve to the next page.
  static int pageIndexForPosition(
    List<ReaderPageSlice> pages,
    int chapterPosition,
  ) {
    if (pages.isEmpty || chapterPosition <= 0) return 0;
    for (var i = 0; i < pages.length; i++) {
      final page = pages[i];
      if (chapterPosition >= page.start && chapterPosition < page.end) {
        return i;
      }
      if (chapterPosition < page.start) return i;
    }
    return pages.length - 1;
  }

  static List<ReaderPageSlice> _paginateWithHardPageBreaks({
    required String text,
    required TextStyle style,
    required double maxWidth,
    required double maxHeight,
    required TextAlign textAlign,
    required double paragraphSpacingTenths,
    required List<ReaderPaginatorPlaceholder> placeholders,
  }) {
    final pages = <ReaderPageSlice>[];
    var segmentStart = 0;
    for (final match in _hardPageBreakLine.allMatches(text)) {
      _appendSegment(
        pages: pages,
        text: text,
        start: segmentStart,
        end: match.start,
        style: style,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        textAlign: textAlign,
        paragraphSpacingTenths: paragraphSpacingTenths,
        placeholders: placeholders,
      );

      // The marker is a layout command. Its following source newline is also
      // not rendered because the original stores it outside TextPage.text.
      segmentStart = match.end;
      if (segmentStart < text.length && text[segmentStart] == '\n') {
        segmentStart++;
      }
    }
    _appendSegment(
      pages: pages,
      text: text,
      start: segmentStart,
      end: text.length,
      style: style,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      textAlign: textAlign,
      paragraphSpacingTenths: paragraphSpacingTenths,
      placeholders: placeholders,
    );
    if (pages.isEmpty) {
      return [ReaderPageSlice(text: '', start: 0, end: text.length)];
    }
    return pages;
  }

  static void _appendSegment({
    required List<ReaderPageSlice> pages,
    required String text,
    required int start,
    required int end,
    required TextStyle style,
    required double maxWidth,
    required double maxHeight,
    required TextAlign textAlign,
    required double paragraphSpacingTenths,
    required List<ReaderPaginatorPlaceholder> placeholders,
  }) {
    if (start >= end) return;
    final segment = text.substring(start, end);
    for (final page in _paginateText(
      text: segment,
      style: style,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      textAlign: textAlign,
      paragraphSpacingTenths: paragraphSpacingTenths,
      placeholders: [
        for (final placeholder in placeholders)
          if (placeholder.start >= start && placeholder.end <= end)
            ReaderPaginatorPlaceholder(
              start: placeholder.start - start,
              end: placeholder.end - start,
              width: placeholder.width,
              height: placeholder.height,
            ),
      ],
    )) {
      pages.add(
        ReaderPageSlice(
          text: page.text,
          start: start + page.start,
          end: start + page.end,
        ),
      );
    }
  }

  static List<ReaderPageSlice> _paginateText({
    required String text,
    required TextStyle style,
    required double maxWidth,
    required double maxHeight,
    required TextAlign textAlign,
    required double paragraphSpacingTenths,
    required List<ReaderPaginatorPlaceholder> placeholders,
  }) {
    if (text.isEmpty) {
      return const [ReaderPageSlice(text: '', start: 0, end: 0)];
    }
    if (maxWidth <= 0 || maxHeight <= 0) {
      return [ReaderPageSlice(text: text, start: 0, end: text.length)];
    }

    final measuredPlaceholders = _effectivePlaceholders(
      text: text,
      style: style,
      placeholders: placeholders,
    );
    final painter = TextPainter(
      text: _textSpanWithPlaceholders(text, style, measuredPlaceholders),
      textDirection: TextDirection.ltr,
      textAlign: textAlign,
    );
    if (measuredPlaceholders.isNotEmpty) {
      painter.setPlaceholderDimensions([
        for (final placeholder in measuredPlaceholders)
          PlaceholderDimensions(
            size: Size(placeholder.width, placeholder.height),
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            baselineOffset: placeholder.height * 0.8,
          ),
      ]);
    }
    painter.layout(maxWidth: maxWidth);
    final metrics = painter.computeLineMetrics();
    if (metrics.isEmpty) {
      return [ReaderPageSlice(text: text, start: 0, end: text.length)];
    }

    final lines = <({int start, int end, double top, double bottom})>[];
    var paragraphOffset = 0.0;
    for (final metric in metrics) {
      final position = painter.getPositionForOffset(Offset(0, metric.baseline));
      final range = painter.getLineBoundary(position);
      if (range.isValid &&
          (lines.isEmpty ||
              range.start != lines.last.start ||
              range.end != lines.last.end)) {
        lines.add((
          start: range.start,
          end: range.end,
          top: metric.baseline - metric.ascent + paragraphOffset,
          bottom: metric.baseline + metric.descent + paragraphOffset,
        ));
        if (paragraphSpacingTenths > 0 &&
            range.end < text.length &&
            text[range.end] == '\n') {
          paragraphOffset +=
              (metric.baseline +
                  metric.descent -
                  (metric.baseline - metric.ascent)) *
              paragraphSpacingTenths /
              10;
        }
      }
    }
    if (lines.isEmpty) {
      return [ReaderPageSlice(text: text, start: 0, end: text.length)];
    }

    final pages = <ReaderPageSlice>[];
    var start = 0;
    while (start < text.length) {
      var lineIndex = lines.indexWhere(
        (line) => start >= line.start && start < line.end,
      );
      if (lineIndex < 0) {
        lineIndex = lines.indexWhere((line) => line.start >= start);
      }
      if (lineIndex < 0) lineIndex = lines.length - 1;

      final pageTop = lines[lineIndex].top;
      var end = start;
      for (var i = lineIndex; i < lines.length; i++) {
        final line = lines[i];
        if (i > lineIndex && line.bottom > pageTop + maxHeight) break;
        if (line.end > end) end = line.end;
      }
      if (end <= start) {
        end = start + 1 > text.length ? text.length : start + 1;
      }
      pages.add(
        ReaderPageSlice(
          text: text.substring(start, end),
          start: start,
          end: end,
        ),
      );
      start = end;
    }
    return pages;
  }

  static List<ReaderPaginatorPlaceholder> _effectivePlaceholders({
    required String text,
    required TextStyle style,
    required List<ReaderPaginatorPlaceholder> placeholders,
  }) {
    final fallbackWidth = (style.fontSize ?? 14) * 1.56;
    final fallbackHeight = (style.fontSize ?? 14) * (style.height ?? 1.2);
    final byStart = <int, ReaderPaginatorPlaceholder>{};
    for (final placeholder in placeholders) {
      if (placeholder.start < 0 ||
          placeholder.end != placeholder.start + 1 ||
          placeholder.end > text.length ||
          text[placeholder.start] != '\uFFFC') {
        continue;
      }
      byStart[placeholder.start] = ReaderPaginatorPlaceholder(
        start: placeholder.start,
        end: placeholder.end,
        width: placeholder.width > 0 ? placeholder.width : fallbackWidth,
        height: placeholder.height > 0 ? placeholder.height : fallbackHeight,
      );
    }
    for (
      var index = text.indexOf('\uFFFC');
      index >= 0;
      index = text.indexOf('\uFFFC', index + 1)
    ) {
      byStart.putIfAbsent(
        index,
        () => ReaderPaginatorPlaceholder(
          start: index,
          end: index + 1,
          width: fallbackWidth,
          height: fallbackHeight,
        ),
      );
    }
    return byStart.values.toList()..sort((a, b) => a.start.compareTo(b.start));
  }

  static InlineSpan _textSpanWithPlaceholders(
    String text,
    TextStyle style,
    List<ReaderPaginatorPlaceholder> placeholders,
  ) {
    if (placeholders.isEmpty) return TextSpan(style: style, text: text);
    final children = <InlineSpan>[];
    var cursor = 0;
    for (final placeholder in placeholders) {
      if (cursor < placeholder.start) {
        children.add(TextSpan(text: text.substring(cursor, placeholder.start)));
      }
      children.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: SizedBox(width: placeholder.width, height: placeholder.height),
        ),
      );
      cursor = placeholder.end;
    }
    if (cursor < text.length) {
      children.add(TextSpan(text: text.substring(cursor)));
    }
    return TextSpan(style: style, children: children);
  }
}
