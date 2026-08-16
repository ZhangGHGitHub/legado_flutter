import 'package:freezed_annotation/freezed_annotation.dart';

part 'reading_position_mapper.freezed.dart';

/// A page range in the original chapter text.
///
/// [start] and [end] are Dart UTF-16 offsets and follow the half-open
/// interval convention [start, end). The displayed text may contain a
/// layout-only newline, so it is intentionally not required to equal the
/// source substring.
@freezed
class ReadingPageRange with _$ReadingPageRange {
  const factory ReadingPageRange({
    required String text,
    required int start,
    required int end,
  }) = _ReadingPageRange;
}

/// Maps stable chapter positions to the current layout's page indexes.
///
/// This class does not measure text. Flutter's existing TextPainter-backed
/// paginator remains the only owner of line breaking and page boundaries.
abstract final class ReadingPositionMapper {
  static int pageIndexForPosition(
    List<ReadingPageRange> pages,
    int chapterPosition,
  ) {
    if (pages.isEmpty || chapterPosition <= 0) return 0;
    for (var i = 0; i < pages.length; i++) {
      final page = pages[i];
      if (chapterPosition >= page.start && chapterPosition < page.end) {
        return i;
      }
      // A [newpage] marker or another layout-only gap belongs to the next
      // page, matching the original reader's position lookup.
      if (chapterPosition < page.start) return i;
    }
    return pages.length - 1;
  }

  static int chapterPositionForPage(
    List<ReadingPageRange> pages,
    int pageIndex,
  ) {
    if (pages.isEmpty) return 0;
    final index = pageIndex.clamp(0, pages.length - 1);
    return pages[index].start;
  }

  static int resolvePageIndex({
    required List<ReadingPageRange> pages,
    int? chapterPosition,
    int? requestedPageIndex,
  }) {
    if (pages.isEmpty) return 0;
    if (chapterPosition != null && chapterPosition >= 0) {
      return pageIndexForPosition(pages, chapterPosition);
    }
    if (requestedPageIndex == -1) return pages.length - 1;
    return (requestedPageIndex ?? 0).clamp(0, pages.length - 1);
  }
}
