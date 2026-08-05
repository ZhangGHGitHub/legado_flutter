import '../../domain/book/book.dart';
import '../../domain/book/chapter.dart';
import '../../domain/source/book_source.dart';

/// 普通阅读器强制刷新当前书籍目录的 application 边界。
abstract interface class ReaderChapterRefreshPort {
  Future<List<Chapter>> refreshChapters(
    Book book, {
    required BookSource source,
  });
}

/// 独立宿主未提供目录刷新能力时的明确空实现。
final class EmptyReaderChapterRefreshPort implements ReaderChapterRefreshPort {
  const EmptyReaderChapterRefreshPort();

  @override
  Future<List<Chapter>> refreshChapters(
    Book book, {
    required BookSource source,
  }) => Future<List<Chapter>>.error(UnsupportedError('目录刷新服务不可用'));
}
