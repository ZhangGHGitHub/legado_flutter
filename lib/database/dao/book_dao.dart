import '../../models/book.dart';
import '../../models/chapter.dart';
import '../database_helper.dart';

/// 书籍 DAO — 薄封装 [DatabaseHelper]（不引入第二套存储栈）
class BookDao {
  BookDao([DatabaseHelper? db]) : _db = db ?? DatabaseHelper();

  final DatabaseHelper _db;

  Future<void> insert(Book book) => _db.insertBook(book);

  Future<List<Book>> getAll() => _db.getBooks();

  Future<void> updateProgress(
    String bookId,
    double progress,
    String? chapter, {
    int pageIndex = 0,
  }) => _db.updateBookProgress(bookId, progress, chapter, pageIndex: pageIndex);

  Future<void> delete(String bookId) => _db.deleteBook(bookId);

  Future<void> updateCover(String bookId, String coverUrl) =>
      _db.updateBookCover(bookId, coverUrl);

  Future<void> updateGroup(String bookId, String group) =>
      _db.updateBookGroup(bookId, group);

  Future<void> insertChapters(List<Chapter> chapters) =>
      _db.insertChapters(chapters);

  Future<List<Chapter>> getChapters(String bookId) => _db.getChapters(bookId);

  Future<void> saveChapterContent(String chapterId, String content) =>
      _db.saveChapterContent(chapterId, content);

  Future<void> clearChapterContent(Chapter chapter) =>
      _db.clearChapterContent(chapter);
}
