import '../../application/reader/reader_chapter_list_port.dart';
import '../../domain/book/chapter.dart';

/// 以回调形式复用现有 BookProvider 的当前目录快照。
final class ReaderChapterListPortAdapter implements ReaderChapterListPort {
  const ReaderChapterListPortAdapter({
    required List<Chapter> Function() chapters,
  }) : _chapters = chapters;

  final List<Chapter> Function() _chapters;

  @override
  List<Chapter> get currentChapters => List<Chapter>.unmodifiable(_chapters());
}
