import '../../application/reader/manga_chapter_content_port.dart';
import '../../domain/book/book.dart';
import '../../domain/book/chapter.dart';

typedef MangaChapterContentLoader =
    Future<String> Function({required Book book, required Chapter chapter});

/// 以回调形式复用现有章节正文读取链路。
final class MangaChapterContentPortAdapter implements MangaChapterContentPort {
  const MangaChapterContentPortAdapter({
    required MangaChapterContentLoader loadChapterContent,
  }) : _loadChapterContent = loadChapterContent;

  final MangaChapterContentLoader _loadChapterContent;

  @override
  Future<String> loadChapterContent({
    required Book book,
    required Chapter chapter,
  }) => _loadChapterContent(book: book, chapter: chapter);
}
