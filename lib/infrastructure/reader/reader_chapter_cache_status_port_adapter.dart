import '../../application/reader/reader_chapter_cache_status_port.dart';

/// 将现有 BookProvider 的章节缓存状态更新接入 application 端口。
final class ReaderChapterCacheStatusPortAdapter
    implements ReaderChapterCacheStatusPort {
  const ReaderChapterCacheStatusPortAdapter({
    required ReaderChapterCacheMarker markChapterDownloaded,
  }) : _markChapterDownloaded = markChapterDownloaded;

  final ReaderChapterCacheMarker _markChapterDownloaded;

  @override
  void markChapterDownloaded(String chapterId) =>
      _markChapterDownloaded(chapterId);
}
