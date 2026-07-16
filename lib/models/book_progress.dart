import 'book.dart';

/// 云端阅读进度 — 对齐 Jingshiro `BookProgress`
class BookProgress {
  final String name;
  final String author;
  final int durChapterIndex;
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

  factory BookProgress.fromBook(
    Book book, {
    required int durChapterIndex,
    required int durChapterPos,
    String? durChapterTitle,
  }) {
    return BookProgress(
      name: book.name,
      author: book.author,
      durChapterIndex: durChapterIndex,
      durChapterPos: durChapterPos,
      durChapterTime: DateTime.now().millisecondsSinceEpoch,
      durChapterTitle: durChapterTitle ?? book.currentChapter,
    );
  }

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

  /// 云端是否严格快于本地
  bool isAheadOf({required int chapterIndex, required int chapterPos}) {
    if (durChapterIndex > chapterIndex) return true;
    if (durChapterIndex == chapterIndex && durChapterPos > chapterPos) {
      return true;
    }
    return false;
  }

  /// 云端是否严格慢于本地（用于「当前进度超过云端」确认）
  bool isBehind({required int chapterIndex, required int chapterPos}) {
    if (durChapterIndex < chapterIndex) return true;
    if (durChapterIndex == chapterIndex && durChapterPos < chapterPos) {
      return true;
    }
    return false;
  }
}
