import '../../application/reader/reader_chapter_content_port.dart';
import '../../domain/book/book.dart';
import '../../domain/book/chapter.dart';

/// 以回调形式复用现有 BookProvider 的缓存正文读取行为。
final class ReaderChapterContentPortAdapter
    implements ReaderChapterContentPort {
  const ReaderChapterContentPortAdapter({
    required Future<String> Function({
      required Book book,
      required Chapter chapter,
    })
    loadChapterContent,
  }) : _loadChapterContent = loadChapterContent;

  final Future<String> Function({required Book book, required Chapter chapter})
  _loadChapterContent;

  @override
  Future<String> loadChapterContent({
    required Book book,
    required Chapter chapter,
  }) => _loadChapterContent(book: book, chapter: chapter);
}
