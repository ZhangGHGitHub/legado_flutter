/// 本地书籍解析结果中的章节。
class LocalBookChapterSnapshot {
  const LocalBookChapterSnapshot({required this.title, required this.content});

  final String title;
  final String content;
}

/// EPUB 元数据和章节解析结果。
class LocalBookEpubSnapshot {
  const LocalBookEpubSnapshot({
    required this.title,
    required this.author,
    required this.chapters,
  });

  final String title;
  final String author;
  final List<LocalBookChapterSnapshot> chapters;
}

/// 本地 TXT/EPUB 解析所需的最小引擎端口。
abstract interface class LocalBookParserPort {
  bool get isAvailable;

  List<LocalBookChapterSnapshot> parseTxtChapters(String content);

  LocalBookEpubSnapshot parseEpub(List<int> data);
}
