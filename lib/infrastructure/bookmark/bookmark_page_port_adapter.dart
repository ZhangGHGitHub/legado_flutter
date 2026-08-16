import '../../application/bookmark/bookmark_page_port.dart';
import '../../domain/annotation/bookmark_snapshot.dart';
import '../../domain/annotation/note_snapshot.dart';
import '../../domain/book/book.dart';
import '../../services/bookmark_migration_service.dart';
import '../../services/bookmark_service.dart';
import '../../services/bookmark_sync_service.dart';
import '../../services/note_service.dart';

/// 将书签、迁移、笔记和 WebDAV service 组合成页面 application 端口。
final class BookmarkPagePortAdapter implements BookmarkPagePort {
  const BookmarkPagePortAdapter({this.syncService});

  final BookmarkSyncService? syncService;

  @override
  bool get isAvailable => BookmarkService.isReady;

  @override
  bool get notesAvailable => NoteService.isReady;

  @override
  BookmarkPageSnapshot load({required Iterable<Book> books}) {
    final notes = NoteService.list();
    BookmarkMigrationService.migrateLegacyNoteSnapshots(
      notes: notes,
      books: books,
    );
    final bookmarks = BookmarkService.listSnapshots();
    final migratedKeys = bookmarks.map(_bookmarkSignature).toSet();
    final marks = <BookmarkPageMark>[
      ...bookmarks.map(BookmarkPageMark.bookmark),
      ...notes
          .where(_isBookmarkNote)
          .where((note) => !_containsMigratedBookmark(note, migratedKeys))
          .map(BookmarkPageMark.legacyBookmark),
      ...notes
          .where((note) => !_isBookmarkNote(note))
          .map(BookmarkPageMark.thought),
    ];
    return BookmarkPageSnapshot(List.unmodifiable(marks));
  }

  @override
  String exportJson() => BookmarkService.exportJson();

  @override
  int importJson(String raw) => BookmarkService.importJson(raw);

  @override
  Future<int> uploadBookmarks() async {
    final sync = syncService;
    if (sync == null) throw StateError('书签同步端口不可用');
    return sync.uploadMerged(local: BookmarkService.list());
  }

  @override
  Future<int> downloadBookmarks() async {
    final sync = syncService;
    if (sync == null) throw StateError('书签同步端口不可用');
    return sync.downloadAndMerge(
      local: BookmarkService.list(),
      apply: (json) async {
        BookmarkService.importJson(json);
      },
    );
  }

  @override
  bool deleteBookmark(int time) {
    if (!BookmarkService.isReady) return false;
    BookmarkService.delete(time);
    return true;
  }

  @override
  bool deleteNote(String id) {
    if (!NoteService.isReady) return false;
    NoteService.delete(id);
    return true;
  }
}

bool _isBookmarkNote(NoteSnapshot note) => note.noteContent.startsWith('书签');

bool _containsMigratedBookmark(NoteSnapshot note, Set<String> migratedKeys) =>
    migratedKeys.contains(
      _noteSignature(
        bookId: note.bookId,
        chapterIndex: note.position,
        chapterPos: note.chapterPos >= 0 ? note.chapterPos : 0,
        chapterName: note.chapterTitle,
        bookText: note.selectedText,
      ),
    );

String _bookmarkSignature(BookmarkSnapshot bookmark) => _noteSignature(
  bookId: bookmark.bookId,
  chapterIndex: bookmark.chapterIndex,
  chapterPos: bookmark.chapterPos,
  chapterName: bookmark.chapterName,
  bookText: bookmark.bookText,
);

String _noteSignature({
  required String bookId,
  required int chapterIndex,
  required int chapterPos,
  required String chapterName,
  required String bookText,
}) =>
    '$bookId\u0000$chapterIndex\u0000$chapterPos\u0000$chapterName\u0000$bookText';
