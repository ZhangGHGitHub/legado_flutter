import '../../domain/book/book.dart';
import '../../domain/repositories/book_repository.dart';

/// 阅读进度写入结果，供上层区分整书 upsert 与局部进度更新。
final class BookProgressWriteResult {
  const BookProgressWriteResult({
    required this.didUpsertBook,
    this.upsertedBook,
  });

  final bool didUpsertBook;
  final Book? upsertedBook;
}

/// 阅读进度的 application 写入边界。
///
/// 这里只负责选择并执行仓储写入，不刷新 Provider 列表、不处理章节缓存
/// 元数据，也不发送通知。pageIndex 原样传递，以保持章内 UTF-16 位置语义。
final class BookProgressController {
  BookProgressController({required BookRepository repository})
    : _repository = repository;

  final BookRepository _repository;

  Future<BookProgressWriteResult> updateProgress(
    String bookId,
    double progress,
    String? chapter, {
    int pageIndex = 0,
    int? durChapterIndex,
    Book? existingBook,
  }) async {
    if (durChapterIndex != null &&
        existingBook != null &&
        existingBook.id == bookId) {
      final next = existingBook.copyWith(
        progress: progress,
        currentChapter: chapter,
        currentPageIndex: pageIndex,
        durChapterIndex: durChapterIndex,
      );
      await _repository.insert(next);
      return BookProgressWriteResult(didUpsertBook: true, upsertedBook: next);
    }

    await _repository.updateProgress(
      bookId,
      progress,
      chapter,
      pageIndex: pageIndex,
    );
    return const BookProgressWriteResult(didUpsertBook: false);
  }
}
