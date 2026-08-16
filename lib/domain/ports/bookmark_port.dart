import '../annotation/bookmark_snapshot.dart';

/// Persistence boundary for independent bookmarks.
abstract interface class BookmarkPort {
  bool get isAvailable;

  List<BookmarkSnapshot> list({String? bookId});

  bool save(BookmarkSnapshot bookmark);

  bool delete(int time);
}
