import '../../application/reader/book_reader_prefs_port.dart';
import '../../services/book_reader_prefs.dart' as service;

/// BookReaderPrefs 的应用端口适配器，保留旧 SharedPreferences 键和默认值。
final class BookReaderPrefsPortAdapter implements BookReaderPrefsPort {
  const BookReaderPrefsPortAdapter();

  @override
  Future<int?> getPageAnim(String bookId) =>
      service.BookReaderPrefs.getPageAnim(bookId);

  @override
  Future<void> setPageAnim(String bookId, int pageAnim) =>
      service.BookReaderPrefs.setPageAnim(bookId, pageAnim);

  @override
  Future<bool> getReSegment(String bookId) =>
      service.BookReaderPrefs.getReSegment(bookId);

  @override
  Future<void> setReSegment(String bookId, bool value) =>
      service.BookReaderPrefs.setReSegment(bookId, value);
}
