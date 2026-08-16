import '../../application/reader/manga_source_presentation_port.dart';
import '../../domain/book/book.dart';
import '../../domain/source/book_source.dart';

typedef MangaBookSourceResolver = BookSource? Function(Book book);

/// 以回调形式复用现有 SourceProvider 的书源匹配和名称展示行为。
final class MangaSourcePresentationPortAdapter
    implements MangaSourcePresentationPort {
  const MangaSourcePresentationPortAdapter({
    required MangaBookSourceResolver findSourceForBook,
  }) : _findSourceForBook = findSourceForBook;

  final MangaBookSourceResolver _findSourceForBook;

  @override
  String sourceNameForBook(Book book) =>
      _findSourceForBook(book)?.bookSourceName ?? '书源';
}
