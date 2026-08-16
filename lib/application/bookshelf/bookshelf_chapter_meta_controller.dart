import '../../domain/book/book.dart';
import '../../domain/repositories/book_repository.dart';

/// 书架章节元数据读取和持久化结果。
final class BookshelfChapterMetaResult {
  const BookshelfChapterMetaResult({
    required this.totalChapterNum,
    required this.durChapterIndex,
    this.updatedBook,
  });

  /// 仓储中当前书籍的章节数量。
  final int totalChapterNum;

  /// [Book.currentChapter] 在章节列表中的下标；未匹配时为 null。
  final int? durChapterIndex;

  /// 元数据发生变化并成功写入时的书籍快照。
  final Book? updatedBook;

  bool get didUpdate => updatedBook != null;

  int get chapterCount => totalChapterNum;
}

/// 书架书籍章节元数据的 application 读取边界。
///
/// 该控制器不管理 Provider 状态或通知，只负责读取章节、计算元数据，
/// 并在元数据变化时将保留其他字段的书籍快照写回仓储。
final class BookshelfChapterMetaController {
  BookshelfChapterMetaController({required BookRepository repository})
    : _repository = repository;

  final BookRepository _repository;

  Future<BookshelfChapterMetaResult> refresh(
    Book book, {
    void Function(BookshelfChapterMetaResult result)? onResolved,
    Book? Function()? latestBook,
  }) async {
    final chapters = await _repository.getChapters(book.id);
    if (chapters.isEmpty) {
      const result = BookshelfChapterMetaResult(
        totalChapterNum: 0,
        durChapterIndex: null,
      );
      onResolved?.call(result);
      return result;
    }

    final currentBook = latestBook?.call() ?? book;
    int? durChapterIndex;
    final currentChapter = currentBook.currentChapter;
    if (currentChapter != null && currentChapter.isNotEmpty) {
      final index = chapters.indexWhere(
        (chapter) => chapter.title == currentChapter,
      );
      if (index >= 0) durChapterIndex = index;
    }

    var updatedBook = currentBook;
    var didUpdate = false;
    if (currentBook.totalChapterNum != chapters.length) {
      updatedBook = updatedBook.copyWith(totalChapterNum: chapters.length);
      didUpdate = true;
    }
    if (durChapterIndex != null &&
        currentBook.durChapterIndex != durChapterIndex) {
      updatedBook = updatedBook.copyWith(durChapterIndex: durChapterIndex);
      didUpdate = true;
    }

    if (!didUpdate) {
      final result = BookshelfChapterMetaResult(
        totalChapterNum: chapters.length,
        durChapterIndex: durChapterIndex,
      );
      onResolved?.call(result);
      return result;
    }

    final result = BookshelfChapterMetaResult(
      totalChapterNum: chapters.length,
      durChapterIndex: durChapterIndex,
      updatedBook: updatedBook,
    );
    onResolved?.call(result);
    await _repository.insert(updatedBook);
    return result;
  }
}
