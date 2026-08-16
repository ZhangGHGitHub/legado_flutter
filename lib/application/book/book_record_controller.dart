import '../../domain/book/book.dart';
import '../../domain/repositories/book_repository.dart';

/// 书籍阅读元数据的 application 写入控制器。
///
/// 这里只复制并持久化 Book 记录字段，不负责列表状态、通知或当前书选择，
/// 因此不会改变章节身份、章节索引、页内阅读位置或正文内容。
final class BookRecordController {
  BookRecordController({required BookRepository repository})
    : _repository = repository;

  final BookRepository _repository;

  Future<Book> updateReadIteration(Book book, int readIteration) async {
    final next = book.copyWith(readIteration: readIteration);
    await _repository.insert(next);
    return next;
  }

  Future<Book> updateSimulatedReading(
    Book book, {
    required bool enabled,
    required String startDate,
    required int startChapter,
    required int dailyChapters,
  }) async {
    final next = book.copyWith(
      simReadEnabled: enabled,
      simReadStartDate: startDate,
      simReadStartChapter: startChapter < 0 ? 0 : startChapter,
      simReadDailyChapters: dailyChapters < 1 ? 3 : dailyChapters.clamp(1, 999),
    );
    await _repository.insert(next);
    return next;
  }
}
