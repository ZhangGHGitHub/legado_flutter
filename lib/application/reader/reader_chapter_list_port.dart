import '../../domain/book/book.dart';
import '../../domain/book/chapter.dart';

/// 普通阅读器读取当前目录快照的 application 边界。
abstract interface class ReaderChapterListPort {
  List<Chapter> currentChaptersFor(Book book);
}

/// 独立宿主未提供目录快照时的回退实现。
final class ReaderChapterListPortCallbacks implements ReaderChapterListPort {
  const ReaderChapterListPortCallbacks({
    required List<Chapter> Function() chapters,
  }) : _chapters = chapters;

  final List<Chapter> Function() _chapters;

  @override
  List<Chapter> currentChaptersFor(Book book) {
    final chapters = _chapters();
    if (chapters.isEmpty || chapters.first.bookId != book.id) return const [];
    return List<Chapter>.unmodifiable(chapters);
  }
}

/// 独立宿主未提供目录快照时的明确空实现。
final class EmptyReaderChapterListPort implements ReaderChapterListPort {
  const EmptyReaderChapterListPort();

  @override
  List<Chapter> currentChaptersFor(Book book) => const [];
}
