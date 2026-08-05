/// 普通阅读器写入章节阅读进度的 application 边界。
abstract interface class ReaderProgressPort {
  Future<void> updateProgress(
    String bookId,
    double progress,
    String? chapter, {
    int pageIndex = 0,
    int? durChapterIndex,
  });
}

typedef ReaderProgressUpdater =
    Future<void> Function(
      String bookId,
      double progress,
      String? chapter, {
      int pageIndex,
      int? durChapterIndex,
    });

/// 独立宿主未提供阅读进度能力时的回调实现。
final class ReaderProgressPortCallbacks implements ReaderProgressPort {
  const ReaderProgressPortCallbacks({required ReaderProgressUpdater update})
    : _update = update;

  final ReaderProgressUpdater _update;

  @override
  Future<void> updateProgress(
    String bookId,
    double progress,
    String? chapter, {
    int pageIndex = 0,
    int? durChapterIndex,
  }) => _update(
    bookId,
    progress,
    chapter,
    pageIndex: pageIndex,
    durChapterIndex: durChapterIndex,
  );
}

/// 独立宿主未提供阅读进度能力时的明确空实现。
final class EmptyReaderProgressPort implements ReaderProgressPort {
  const EmptyReaderProgressPort();

  @override
  Future<void> updateProgress(
    String bookId,
    double progress,
    String? chapter, {
    int pageIndex = 0,
    int? durChapterIndex,
  }) => Future<void>.error(UnsupportedError('阅读进度服务不可用'));
}
