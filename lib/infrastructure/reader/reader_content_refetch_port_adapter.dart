import '../../application/reader/reader_content_refetch_port.dart';
import '../../domain/book/book.dart';
import '../../domain/book/chapter.dart';
import '../../domain/ports/reader_content_source_port.dart';
import '../../domain/source/book_source.dart';

typedef ReaderBookSourceResolver = BookSource? Function(Book book);

/// 复用当前书源解析和正文获取链路的 adapter。
final class ReaderContentRefetchPortAdapter
    implements ReaderContentRefetchPort {
  const ReaderContentRefetchPortAdapter({
    required ReaderContentSourcePort contentSource,
    required ReaderBookSourceResolver resolveSource,
  }) : _contentSource = contentSource,
       _resolveSource = resolveSource;

  final ReaderContentSourcePort _contentSource;
  final ReaderBookSourceResolver _resolveSource;

  @override
  Future<String> fetchRawContent({
    required Book book,
    required Chapter chapter,
  }) async {
    final source = _resolveSource(book);
    if (source == null) return '';
    return _contentSource.getChapterContent(chapter.url, source: source);
  }
}
