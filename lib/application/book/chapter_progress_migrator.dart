import '../../domain/book/chapter.dart';

/// 阅读位置在目录刷新后的迁移结果。
class ChapterProgress {
  final int chapterIndex;
  final int chapterPos;

  const ChapterProgress({required this.chapterIndex, required this.chapterPos});
}

/// 将旧目录中的阅读位置迁移到刷新后的目录。
///
/// 目录项的匹配优先使用 URL，其次使用标题。只有两者都无法确认时，
/// 才按旧索引落到新目录，并将字符位置重置，避免把旧章位置带入另一章。
class ChapterProgressMigrator {
  const ChapterProgressMigrator._();

  static ChapterProgress migrate({
    required List<Chapter> oldChapters,
    required List<Chapter> newChapters,
    required int oldChapterIndex,
    required int oldChapterPos,
    int? newChapterLength,
  }) {
    if (newChapters.isEmpty) {
      return const ChapterProgress(chapterIndex: 0, chapterPos: 0);
    }

    final safeOldIndex = _clampIndex(oldChapterIndex, oldChapters.length);
    final oldChapter = safeOldIndex == null ? null : oldChapters[safeOldIndex];
    final matchedIndex = _findMatchingIndex(oldChapter, newChapters);
    final chapterIndex =
        matchedIndex ?? _clampIndex(oldChapterIndex, newChapters.length) ?? 0;
    final sameChapter = matchedIndex != null;
    final position = sameChapter
        ? _clampPosition(oldChapterPos, newChapterLength)
        : 0;

    return ChapterProgress(chapterIndex: chapterIndex, chapterPos: position);
  }

  static int? _findMatchingIndex(
    Chapter? oldChapter,
    List<Chapter> newChapters,
  ) {
    if (oldChapter == null) return null;

    if (oldChapter.url.isNotEmpty) {
      final urlIndex = newChapters.indexWhere(
        (chapter) => chapter.url.isNotEmpty && chapter.url == oldChapter.url,
      );
      if (urlIndex >= 0) return urlIndex;
    }

    final titleIndex = newChapters.indexWhere(
      (chapter) => chapter.title == oldChapter.title,
    );
    return titleIndex >= 0 ? titleIndex : null;
  }

  static int? _clampIndex(int index, int length) {
    if (length == 0) return null;
    if (index < 0) return 0;
    if (index >= length) return length - 1;
    return index;
  }

  static int _clampPosition(int position, int? length) {
    final nonNegative = position < 0 ? 0 : position;
    if (length == null || length < 0) return nonNegative;
    return nonNegative.clamp(0, length);
  }
}
