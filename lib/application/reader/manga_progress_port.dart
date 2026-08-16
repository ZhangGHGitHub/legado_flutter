/// 漫画阅读页写入章节阅读进度所需的应用端口。
abstract interface class MangaProgressPort {
  Future<void> updateProgress(
    String bookId,
    double progress,
    String? chapter, {
    int pageIndex = 0,
    int? durChapterIndex,
  });
}
