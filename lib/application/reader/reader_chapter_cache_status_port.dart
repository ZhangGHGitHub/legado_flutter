/// 普通阅读器更新当前目录章节缓存状态的 application 边界。
abstract interface class ReaderChapterCacheStatusPort {
  void markChapterDownloaded(String chapterId);
}

typedef ReaderChapterCacheMarker = void Function(String chapterId);

/// 独立宿主未提供章节缓存状态能力时的回调实现。
final class ReaderChapterCacheStatusPortCallbacks
    implements ReaderChapterCacheStatusPort {
  const ReaderChapterCacheStatusPortCallbacks({
    required ReaderChapterCacheMarker markChapterDownloaded,
  }) : _markChapterDownloaded = markChapterDownloaded;

  final ReaderChapterCacheMarker _markChapterDownloaded;

  @override
  void markChapterDownloaded(String chapterId) =>
      _markChapterDownloaded(chapterId);
}

/// 独立宿主未提供章节缓存状态能力时的明确空实现。
final class EmptyReaderChapterCacheStatusPort
    implements ReaderChapterCacheStatusPort {
  const EmptyReaderChapterCacheStatusPort();

  @override
  void markChapterDownloaded(String chapterId) {}
}
