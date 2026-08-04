import '../../domain/book/book.dart';
import '../../domain/book/chapter.dart';

/// 有声/阅读页面按书籍和章节读取缓存正文所需的应用端口。
abstract interface class ReaderChapterContentPort {
  Future<String> loadChapterContent({
    required Book book,
    required Chapter chapter,
  });
}

/// 独立宿主未提供正文读取能力时的明确空实现。
final class EmptyReaderChapterContentPort implements ReaderChapterContentPort {
  const EmptyReaderChapterContentPort();

  @override
  Future<String> loadChapterContent({
    required Book book,
    required Chapter chapter,
  }) => Future<String>.error(UnsupportedError('正文服务不可用'));
}
