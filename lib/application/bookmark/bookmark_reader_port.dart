import '../../domain/book/book.dart';
import '../../domain/book/chapter.dart';
import '../../domain/source/book_source.dart';

/// 书签页跳转阅读器所需的书架和目录能力。
abstract interface class BookmarkReaderPort {
  Book? findBookById(String bookId);

  List<Chapter> get currentChapters;

  Future<void> loadChapters(Book book, {required BookSource source});

  Future<List<Chapter>> getLocalChapters(String bookId);
}

/// 独立宿主未提供阅读跳转能力时的明确空实现。
final class EmptyBookmarkReaderPort implements BookmarkReaderPort {
  const EmptyBookmarkReaderPort();

  @override
  Book? findBookById(String bookId) => null;

  @override
  List<Chapter> get currentChapters => const [];

  @override
  Future<void> loadChapters(Book book, {required BookSource source}) =>
      Future<void>.error(UnsupportedError('阅读目录服务不可用'));

  @override
  Future<List<Chapter>> getLocalChapters(String bookId) =>
      Future<List<Chapter>>.value(const []);
}
