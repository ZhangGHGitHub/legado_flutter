import '../../domain/book/book.dart';
import '../../domain/book/chapter.dart';
import '../../domain/repositories/book_repository.dart';

/// 目录页读取书籍状态并保存目录顺序所需的 application 边界。
abstract interface class TocPersistencePort {
  Future<Book?> findBookById(String bookId);

  Future<List<Chapter>> getChapters(String bookId);

  Future<void> saveChapters(List<Chapter> chapters);

  Future<void> saveBook(Book book);
}

/// 将既有书籍仓储接入目录页端口。
final class TocPersistencePortCallbacks implements TocPersistencePort {
  const TocPersistencePortCallbacks({
    required Future<Book?> Function(String bookId) findBookById,
    required Future<List<Chapter>> Function(String bookId) getChapters,
    required Future<void> Function(List<Chapter> chapters) saveChapters,
    required Future<void> Function(Book book) saveBook,
  }) : _findBookById = findBookById,
       _getChapters = getChapters,
       _saveChapters = saveChapters,
       _saveBook = saveBook;

  factory TocPersistencePortCallbacks.fromRepository(
    BookRepository repository,
  ) {
    return TocPersistencePortCallbacks(
      findBookById: (bookId) async {
        final books = await repository.getAll();
        for (final book in books) {
          if (book.id == bookId) return book;
        }
        return null;
      },
      getChapters: repository.getChapters,
      saveChapters: repository.insertChapters,
      saveBook: repository.insert,
    );
  }

  final Future<Book?> Function(String bookId) _findBookById;
  final Future<List<Chapter>> Function(String bookId) _getChapters;
  final Future<void> Function(List<Chapter> chapters) _saveChapters;
  final Future<void> Function(Book book) _saveBook;

  @override
  Future<Book?> findBookById(String bookId) => _findBookById(bookId);

  @override
  Future<List<Chapter>> getChapters(String bookId) => _getChapters(bookId);

  @override
  Future<void> saveChapters(List<Chapter> chapters) => _saveChapters(chapters);

  @override
  Future<void> saveBook(Book book) => _saveBook(book);
}

/// 独立宿主未提供目录持久化能力时的明确空实现。
final class EmptyTocPersistencePort implements TocPersistencePort {
  const EmptyTocPersistencePort();

  @override
  Future<Book?> findBookById(String bookId) async => null;

  @override
  Future<List<Chapter>> getChapters(String bookId) async => const [];

  @override
  Future<void> saveChapters(List<Chapter> chapters) async {}

  @override
  Future<void> saveBook(Book book) async {}
}
