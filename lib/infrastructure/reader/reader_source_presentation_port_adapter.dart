import '../../application/reader/reader_source_presentation_port.dart';
import '../../domain/book/book.dart';
import '../../domain/source/book_source.dart';

typedef ReaderBookSourceResolver = BookSource? Function(Book book);

/// 以回调形式复用现有 SourceProvider 的书源匹配和名称展示行为。
final class ReaderSourcePresentationPortAdapter
    implements ReaderSourcePresentationPort {
  const ReaderSourcePresentationPortAdapter({
    required ReaderBookSourceResolver findSourceForBook,
  }) : _findSourceForBook = findSourceForBook;

  final ReaderBookSourceResolver _findSourceForBook;

  @override
  String sourceNameForBook(Book book) {
    final source = _findSourceForBook(book);
    if (source != null && source.bookSourceName.isNotEmpty) {
      return source.bookSourceName;
    }

    final url = book.bookSourceUrl.isNotEmpty
        ? book.bookSourceUrl
        : book.sourceUrl;
    if (url.isEmpty) return '';

    final host = Uri.tryParse(url)?.host;
    return (host != null && host.isNotEmpty) ? host : url;
  }
}
