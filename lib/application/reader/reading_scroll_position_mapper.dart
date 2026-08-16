/// Maps a vertical scroll offset to a chapter position.
///
/// The mapper deliberately does not measure text. Layout remains owned by
/// Flutter's text layout engine; this class only maps the scroll extent to a
/// UTF-16 position in the already laid out chapter.
abstract final class ReadingScrollPositionMapper {
  /// Returns the scrollable extent for a content viewport pair.
  static double maxScrollExtent({
    required double viewportHeight,
    required double contentHeight,
  }) {
    final viewport = viewportHeight.isFinite && viewportHeight > 0
        ? viewportHeight
        : 0.0;
    final content = contentHeight.isFinite && contentHeight > 0
        ? contentHeight
        : 0.0;
    return (content - viewport).clamp(0.0, double.infinity).toDouble();
  }

  /// Converts [offset] to a UTF-16 chapter position.
  ///
  /// [contentLength] must be the Dart UTF-16 length of the chapter (usually
  /// `chapterText.length`). The offset is clamped to the same range as a
  /// Flutter scroll position. When the content fits in the viewport there is
  /// no meaningful scroll position, so the chapter start (0) is returned.
  static int chapterPositionForOffset({
    required double offset,
    required double viewportHeight,
    required double contentHeight,
    required int contentLength,
  }) {
    final length = contentLength < 0 ? 0 : contentLength;
    if (length == 0) return 0;

    final extent = maxScrollExtent(
      viewportHeight: viewportHeight,
      contentHeight: contentHeight,
    );
    if (extent == 0 || offset.isNaN) return 0;

    final clampedOffset = offset.clamp(0.0, extent).toDouble();
    final ratio = clampedOffset / extent;
    return (length * ratio).round().clamp(0, length);
  }
}
