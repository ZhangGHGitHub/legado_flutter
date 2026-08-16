import '../../domain/annotation/bookmark_snapshot.dart';
import '../../domain/annotation/note_snapshot.dart';
import '../../domain/book/book.dart';

/// Bookmark and note data exposed to the bookmark page.
final class BookmarkPageMark {
  const BookmarkPageMark.bookmark(this.bookmark)
    : thought = null,
      isLegacyBookmark = false;

  const BookmarkPageMark.thought(this.thought)
    : bookmark = null,
      isLegacyBookmark = false;

  const BookmarkPageMark.legacyBookmark(this.thought)
    : bookmark = null,
      isLegacyBookmark = true;

  final BookmarkSnapshot? bookmark;
  final NoteSnapshot? thought;
  final bool isLegacyBookmark;

  bool get isBookmark => bookmark != null || isLegacyBookmark;

  String get id =>
      bookmark != null ? 'bookmark:${bookmark!.time}' : 'note:${thought!.id}';

  String get bookId => bookmark?.bookId ?? thought!.bookId;

  String get bookName => bookmark?.bookName ?? thought!.bookId;

  String get bookAuthor => bookmark?.bookAuthor ?? '';

  String get chapterTitle => bookmark?.chapterName ?? thought!.chapterTitle;

  String get selectedText => bookmark?.bookText ?? thought!.selectedText;

  String get noteContent => bookmark?.content ?? thought!.noteContent;

  int get position => bookmark?.chapterIndex ?? thought!.position;

  int get chapterPos => bookmark?.chapterPos ?? thought!.chapterPos;

  String get createdAt => bookmark == null
      ? thought!.createdAt
      : DateTime.fromMillisecondsSinceEpoch(bookmark!.time).toIso8601String();
}

final class BookmarkPageSnapshot {
  const BookmarkPageSnapshot(this.marks);

  const BookmarkPageSnapshot.empty() : marks = const [];

  final List<BookmarkPageMark> marks;
}

/// Application boundary for bookmark page reads and commands.
abstract interface class BookmarkPagePort {
  bool get isAvailable;

  bool get notesAvailable;

  BookmarkPageSnapshot load({required Iterable<Book> books});

  String exportJson();

  int importJson(String raw);

  Future<int> uploadBookmarks();

  Future<int> downloadBookmarks();

  bool deleteBookmark(int time);

  bool deleteNote(String id);
}

/// Used when the application composition root has not provided the feature.
final class UnavailableBookmarkPagePort implements BookmarkPagePort {
  const UnavailableBookmarkPagePort();

  @override
  bool get isAvailable => false;

  @override
  bool get notesAvailable => false;

  @override
  BookmarkPageSnapshot load({required Iterable<Book> books}) =>
      const BookmarkPageSnapshot.empty();

  @override
  String exportJson() => '[]';

  @override
  int importJson(String raw) => 0;

  @override
  Future<int> uploadBookmarks() => Future<int>.error(StateError('书签应用端口不可用'));

  @override
  Future<int> downloadBookmarks() => Future<int>.error(StateError('书签应用端口不可用'));

  @override
  bool deleteBookmark(int time) => false;

  @override
  bool deleteNote(String id) => false;
}
