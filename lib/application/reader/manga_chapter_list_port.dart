import '../../domain/book/chapter.dart';

/// 漫画阅读页换源后读取当前目录所需的应用端口。
abstract interface class MangaChapterListPort {
  List<Chapter> get currentChapters;
}

/// 独立宿主未提供目录快照时的明确空实现。
final class EmptyMangaChapterListPort implements MangaChapterListPort {
  const EmptyMangaChapterListPort();

  @override
  List<Chapter> get currentChapters => const [];
}
