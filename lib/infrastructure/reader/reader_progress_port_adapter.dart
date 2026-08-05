import '../../application/reader/reader_progress_port.dart';

/// 将现有 BookProvider 的阅读进度写入接入 application 端口。
final class ReaderProgressPortAdapter implements ReaderProgressPort {
  const ReaderProgressPortAdapter({required ReaderProgressUpdater update})
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
