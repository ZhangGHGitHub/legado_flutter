import '../../bridge/legado_db_bridge.dart';
import '../../bridge/legado_engine_bridge.dart';
import '../../domain/annotation/bookmark_snapshot.dart';
import '../../domain/ports/bookmark_port.dart';
import '../../src/rust/api.dart' as rust_api;

/// Rust/FRB adapter for independent bookmark persistence.
class FrbBookmarkPort implements BookmarkPort {
  @override
  bool get isAvailable =>
      LegadoEngineBridge.isAvailable && LegadoDbBridge.isReady;

  @override
  List<BookmarkSnapshot> list({String? bookId}) {
    if (!isAvailable) return const [];
    return rust_api
        .listBookmarks(bookId: bookId ?? '')
        .map(_fromDto)
        .toList(growable: false);
  }

  @override
  bool save(BookmarkSnapshot bookmark) {
    if (!isAvailable) return false;
    rust_api.upsertBookmark(
      time: bookmark.time,
      bookId: bookmark.bookId,
      bookName: bookmark.bookName,
      bookAuthor: bookmark.bookAuthor,
      chapterIndex: bookmark.chapterIndex,
      chapterPos: bookmark.chapterPos,
      chapterName: bookmark.chapterName,
      bookText: bookmark.bookText,
      content: bookmark.content,
    );
    return true;
  }

  @override
  bool delete(int time) {
    if (!isAvailable) return false;
    rust_api.deleteBookmark(time: time);
    return true;
  }

  static BookmarkSnapshot _fromDto(rust_api.BookmarkDto bookmark) {
    return BookmarkSnapshot(
      time: bookmark.time,
      bookId: bookmark.bookId,
      bookName: bookmark.bookName,
      bookAuthor: bookmark.bookAuthor,
      chapterIndex: bookmark.chapterIndex,
      chapterPos: bookmark.chapterPos,
      chapterName: bookmark.chapterName,
      bookText: bookmark.bookText,
      content: bookmark.content,
    );
  }
}
