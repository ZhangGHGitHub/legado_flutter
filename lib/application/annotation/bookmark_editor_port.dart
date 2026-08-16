/// Application boundary for creating and updating a bookmark from the editor.
abstract interface class BookmarkEditorPort {
  bool get isAvailable;

  /// Returns the persisted timestamp, or null when the write is unavailable.
  int? save({
    int? time,
    required String bookId,
    required String bookName,
    required String bookAuthor,
    required int chapterIndex,
    required int chapterPos,
    required String chapterName,
    required String bookText,
    String content = '',
  });
}

/// Used before the composition root provides the annotation adapter.
final class UnavailableBookmarkEditorPort implements BookmarkEditorPort {
  const UnavailableBookmarkEditorPort();

  @override
  bool get isAvailable => false;

  @override
  int? save({
    int? time,
    required String bookId,
    required String bookName,
    required String bookAuthor,
    required int chapterIndex,
    required int chapterPos,
    required String chapterName,
    required String bookText,
    String content = '',
  }) => null;
}
