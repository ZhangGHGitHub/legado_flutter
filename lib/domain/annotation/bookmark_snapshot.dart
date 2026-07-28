/// Pure Dart representation of an independent bookmark.
///
/// The snapshot is deliberately kept free of FRB/Rust types so bookmark
/// persistence can be replaced or tested without loading the engine.
class BookmarkSnapshot {
  const BookmarkSnapshot({
    required this.time,
    required this.bookId,
    required this.bookName,
    required this.bookAuthor,
    required this.chapterIndex,
    required this.chapterPos,
    required this.chapterName,
    required this.bookText,
    required this.content,
  });

  final int time;
  final String bookId;
  final String bookName;
  final String bookAuthor;
  final int chapterIndex;
  final int chapterPos;
  final String chapterName;
  final String bookText;
  final String content;

  @override
  int get hashCode =>
      time.hashCode ^
      bookId.hashCode ^
      bookName.hashCode ^
      bookAuthor.hashCode ^
      chapterIndex.hashCode ^
      chapterPos.hashCode ^
      chapterName.hashCode ^
      bookText.hashCode ^
      content.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookmarkSnapshot &&
          time == other.time &&
          bookId == other.bookId &&
          bookName == other.bookName &&
          bookAuthor == other.bookAuthor &&
          chapterIndex == other.chapterIndex &&
          chapterPos == other.chapterPos &&
          chapterName == other.chapterName &&
          bookText == other.bookText &&
          content == other.content;
}
