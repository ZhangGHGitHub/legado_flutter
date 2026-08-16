import '../../domain/book/book.dart';

/// 普通阅读器模拟追读书籍读写的 application 边界。
abstract interface class ReaderSimulatedReadingPort {
  Book? findBookById(String bookId);

  Future<Book> updateSimulatedReading(
    Book book, {
    required bool enabled,
    required String startDate,
    required int startChapter,
    required int dailyChapters,
  });
}

typedef ReaderSimulatedBookFinder = Book? Function(String bookId);
typedef ReaderSimulatedReadingUpdater =
    Future<Book> Function(
      Book book, {
      required bool enabled,
      required String startDate,
      required int startChapter,
      required int dailyChapters,
    });

/// 独立宿主未提供模拟追读能力时的回调实现。
final class ReaderSimulatedReadingPortCallbacks
    implements ReaderSimulatedReadingPort {
  const ReaderSimulatedReadingPortCallbacks({
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

/// 独立宿主未提供模拟追读能力时的明确空实现。
final class EmptyReaderSimulatedReadingPort
    implements ReaderSimulatedReadingPort {
  const EmptyReaderSimulatedReadingPort();

  @override
  Book? findBookById(String bookId) => null;

  @override
  Future<Book> updateSimulatedReading(
    Book book, {
    required bool enabled,
    required String startDate,
    required int startChapter,
    required int dailyChapters,
  }) => Future<Book>.error(UnsupportedError('模拟追读服务不可用'));
}
