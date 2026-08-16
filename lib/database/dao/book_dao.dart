import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import '../../domain/repositories/book_repository.dart';
import '../database_helper.dart';

/// 书籍 DAO — 薄封装 [DatabaseHelper]（不引入第二套存储栈）
/// 当前 SQLite/Rust 适配器；Provider 通过 [BookRepository] 使用它。
class BookDao implements BookRepository, BookCustomCoverRepository {
  BookDao([DatabaseHelper? db]) : _db = db ?? DatabaseHelper();

  final DatabaseHelper _db;

  @override
  Future<void> insert(Book book) => _db.insertBook(book);

  @override
  Future<List<Book>> getAll() => _db.getBooks();

  @override
  Future<void> updateProgress(
    String bookId,
    double progress,
    String? chapter, {
    int pageIndex = 0,
  }) => _db.updateBookProgress(bookId, progress, chapter, pageIndex: pageIndex);

  @override
  Future<void> delete(String bookId) => _db.deleteBook(bookId);

  @override
  Future<void> updateCover(String bookId, String coverUrl) =>
      _db.updateBookCover(bookId, coverUrl);

  @override
  Future<void> updateCustomCover(String bookId, String customCoverUrl) =>
      _db.updateBookCustomCover(bookId, customCoverUrl);

  @override
  Future<void> updateBookDetails(
    String bookId,
    String name,
    String author,
    String description,
  ) => _db.updateBookDetails(bookId, name, author, description);

  @override
  Future<void> updateGroup(String bookId, String group) =>
      _db.updateBookGroup(bookId, group);

  @override
  Future<void> insertChapters(List<Chapter> chapters) =>
      _db.insertChapters(chapters);

  @override
  Future<List<Chapter>> getChapters(String bookId) => _db.getChapters(bookId);

  @override
  Future<String?> getChapterContent(String chapterId) =>
      _db.getChapterContent(chapterId);

  @override
  Future<void> saveChapterContent(String chapterId, String content) =>
      _db.saveChapterContent(chapterId, content);

  @override
  Future<void> clearChapterContent(Chapter chapter) =>
      _db.clearChapterContent(chapter);
}
