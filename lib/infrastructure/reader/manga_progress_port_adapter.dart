import '../../application/reader/manga_progress_port.dart';

typedef MangaProgressUpdater =
    Future<void> Function(
      String bookId,
      double progress,
      String? chapter, {
      int pageIndex,
      int? durChapterIndex,
    });

/// 以回调形式复用现有书籍进度更新链路。
final class MangaProgressPortAdapter implements MangaProgressPort {
  const MangaProgressPortAdapter({required MangaProgressUpdater updateProgress})
    : _updateProgress = updateProgress;

  final MangaProgressUpdater _updateProgress;

  @override
  Future<void> updateProgress(
    String bookId,
    double progress,
    String? chapter, {
    int pageIndex = 0,
    int? durChapterIndex,
  }) => _updateProgress(
    bookId,
    progress,
    chapter,
    pageIndex: pageIndex,
    durChapterIndex: durChapterIndex,
  );
}
