import '../domain/ports/chapter_content_cache_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';

/// 书籍缓存导出 — 对齐 Jingshiro `CacheBook` 的纯文本导出路径。
class BookCacheExportService {
  const BookCacheExportService({required this.contentCache});

  final ChapterContentCachePort contentCache;

  Future<String> buildText({
    required Book book,
    required List<Chapter> chapters,
  }) async {
    final cachedIds = await contentCache.listChapterIds(book.id);
    final buffer = StringBuffer();
    buffer.writeln(book.name);
    if (book.author.trim().isNotEmpty) buffer.writeln('作者：${book.author}');
    buffer.writeln();

    var count = 0;
    final ordered = List<Chapter>.from(chapters)
      ..sort((a, b) => a.index.compareTo(b.index));
    for (final chapter in ordered) {
      if (!cachedIds.contains(contentCache.sanitizeChapterId(chapter.id))) {
        continue;
      }
      final content = await contentCache.get(book.id, chapter.id);
      if (content == null || content.trim().isEmpty) continue;
      buffer
        ..writeln('【${chapter.title}】')
        ..writeln(content.trim())
        ..writeln();
      count++;
    }
    return count == 0 ? '' : buffer.toString().trimRight();
  }

  Future<String> buildBooksText({
    required List<Book> books,
    required Future<List<Chapter>> Function(String bookId) loadChapters,
  }) async {
    final sections = <String>[];
    for (final book in books) {
      final text = await buildText(
        book: book,
        chapters: await loadChapters(book.id),
      );
      if (text.isNotEmpty) sections.add(text);
    }
    return sections.join('\n\n${'=' * 24}\n\n');
  }
}
