/// 云端阅读进度，对齐原版 `BookProgress` 的持久化字段。
class BookProgress {
  final String name;
  final String author;
  final int durChapterIndex;

  /// UTF-16 章内位置，与原版和阅读位置迁移契约一致。
  final int durChapterPos;
  final int durChapterTime;
  final String? durChapterTitle;

  const BookProgress({
    required this.name,
    required this.author,
    required this.durChapterIndex,
    required this.durChapterPos,
    required this.durChapterTime,
    this.durChapterTitle,
  });

  factory BookProgress.fromJson(Map<String, dynamic> json) {
    return BookProgress(
      name: json['name'] as String? ?? '',
      author: json['author'] as String? ?? '',
      durChapterIndex: (json['durChapterIndex'] as num?)?.toInt() ?? 0,
      durChapterPos: (json['durChapterPos'] as num?)?.toInt() ?? 0,
      durChapterTime: (json['durChapterTime'] as num?)?.toInt() ?? 0,
      durChapterTitle: json['durChapterTitle'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'author': author,
    'durChapterIndex': durChapterIndex,
    'durChapterPos': durChapterPos,
    'durChapterTime': durChapterTime,
    'durChapterTitle': durChapterTitle,
  };

  bool isAheadOf({required int chapterIndex, required int chapterPos}) {
    if (durChapterIndex > chapterIndex) return true;
    if (durChapterIndex == chapterIndex && durChapterPos > chapterPos) {
      return true;
    }
    return false;
  }

  bool isBehind({required int chapterIndex, required int chapterPos}) {
    if (durChapterIndex < chapterIndex) return true;
    if (durChapterIndex == chapterIndex && durChapterPos < chapterPos) {
      return true;
    }
    return false;
  }
}
