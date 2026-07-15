import '../../help/book_help.dart';
import '../../models/chapter.dart';
import 'download_choice_dialog.dart';

/// 按下载选项筛选章节
List<Chapter> filterChaptersForDownload(
  List<Chapter> chapters,
  DownloadChoiceResult choice, {
  required int startIndex,
  required Set<String> cachedIds,
}) {
  bool isCached(Chapter c) =>
      c.isDownloaded || cachedIds.contains(BookHelp.sanitizeId(c.id));

  final start = startIndex.clamp(0, chapters.isEmpty ? 0 : chapters.length - 1);
  switch (choice.range) {
    case DownloadRangeKind.all:
      return List<Chapter>.from(chapters);
    case DownloadRangeKind.notCached:
      return chapters.where((c) => !isCached(c)).toList();
    case DownloadRangeKind.fromCurrent:
      return chapters.skip(start).toList();
    case DownloadRangeKind.nextN:
      return chapters.skip(start).take(choice.nextCount).toList();
  }
}
