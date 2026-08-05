import '../../application/reader/reader_simulated_reading_port.dart';
import '../../domain/book/book.dart';

/// 将现有 BookProvider 的模拟追读读写接入 application 端口。
final class ReaderSimulatedReadingPortAdapter
    implements ReaderSimulatedReadingPort {
  const ReaderSimulatedReadingPortAdapter({
    required ReaderSimulatedBookFinder findBookById,
    required ReaderSimulatedReadingUpdater updateSimulatedReading,
  }) : _findBookById = findBookById,
       _updateSimulatedReading = updateSimulatedReading;

  final ReaderSimulatedBookFinder _findBookById;
  final ReaderSimulatedReadingUpdater _updateSimulatedReading;

  @override
  Book? findBookById(String bookId) => _findBookById(bookId);

  @override
  Future<Book> updateSimulatedReading(
    Book book, {
    required bool enabled,
    required String startDate,
    required int startChapter,
    required int dailyChapters,
  }) => _updateSimulatedReading(
    book,
    enabled: enabled,
    startDate: startDate,
    startChapter: startChapter,
    dailyChapters: dailyChapters,
  );
}
