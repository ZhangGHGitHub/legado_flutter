import '../../domain/book/book.dart';
import '../../domain/reader/book_progress.dart';

abstract final class BookProgressFactory {
  static BookProgress fromBook(
    Book book, {
    required int durChapterIndex,
    required int durChapterPos,
    String? durChapterTitle,
    DateTime Function()? now,
  }) {
    return BookProgress(
      name: book.name,
      author: book.author,
      durChapterIndex: durChapterIndex,
      durChapterPos: durChapterPos,
      durChapterTime: (now ?? DateTime.now)().millisecondsSinceEpoch,
      durChapterTitle: durChapterTitle ?? book.currentChapter,
    );
  }
}
