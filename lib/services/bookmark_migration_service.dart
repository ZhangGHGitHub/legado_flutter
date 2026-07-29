import 'package:legado_flutter/domain/book/book.dart';
import '../domain/annotation/bookmark_snapshot.dart';
import '../domain/annotation/note_snapshot.dart';
import 'bookmark_service.dart';

/// 将旧 notes 表中以「书签」前缀标记的记录转换为独立 Bookmark。
abstract final class BookmarkMigrationService {
  static List<BookmarkSnapshot> convertLegacyNoteSnapshots({
    required Iterable<NoteSnapshot> notes,
    required Map<String, Book> books,
    Set<int> reservedTimes = const <int>{},
  }) {
    final used = {...reservedTimes};
    final converted = <BookmarkSnapshot>[];
    for (final note in notes) {
      if (!note.noteContent.startsWith('书签')) continue;
      var time = _timeForSnapshot(note);
      while (used.contains(time)) {
        time++;
      }
      used.add(time);
      final book = books[note.bookId];
      converted.add(
        BookmarkSnapshot(
          time: time,
          bookId: note.bookId,
          bookName: book?.name ?? note.bookId,
          bookAuthor: book?.author ?? '',
          chapterIndex: note.position,
          chapterPos: note.chapterPos >= 0 ? note.chapterPos : 0,
          chapterName: note.chapterTitle,
          bookText: note.selectedText,
          content: '',
        ),
      );
    }
    return converted;
  }

  static int migrateLegacyNoteSnapshots({
    required Iterable<NoteSnapshot> notes,
    required Iterable<Book> books,
  }) {
    if (!BookmarkService.isReady) return 0;
    final existingBookmarks = BookmarkService.listSnapshots();
    final existing = existingBookmarks.map((bookmark) => bookmark.time).toSet();
    final existingBySignature = <String, int>{
      for (final bookmark in existingBookmarks)
        _signature(
          bookId: bookmark.bookId,
          chapterIndex: bookmark.chapterIndex,
          chapterPos: bookmark.chapterPos,
          chapterName: bookmark.chapterName,
          bookText: bookmark.bookText,
        ): bookmark.time,
    };
    final converted = convertLegacyNoteSnapshots(
      notes: notes,
      books: {for (final book in books) book.id: book},
      reservedTimes: existing,
    );
    var migrated = 0;
    for (final bookmark in converted) {
      final signature = _signature(
        bookId: bookmark.bookId,
        chapterIndex: bookmark.chapterIndex,
        chapterPos: bookmark.chapterPos,
        chapterName: bookmark.chapterName,
        bookText: bookmark.bookText,
      );
      final time = existingBySignature[signature] ?? bookmark.time;
      if (BookmarkService.save(
            time: time,
            bookId: bookmark.bookId,
            bookName: bookmark.bookName,
            bookAuthor: bookmark.bookAuthor,
            chapterIndex: bookmark.chapterIndex,
            chapterPos: bookmark.chapterPos,
            chapterName: bookmark.chapterName,
            bookText: bookmark.bookText,
            content: bookmark.content,
          ) !=
          null) {
        migrated++;
      }
    }
    return migrated;
  }

  static List<BookmarkSnapshot> convertLegacyNotes({
    required Iterable<NoteSnapshot> notes,
    required Map<String, Book> books,
    Set<int> reservedTimes = const <int>{},
  }) => convertLegacyNoteSnapshots(
    notes: notes,
    books: books,
    reservedTimes: reservedTimes,
  );

  /// 迁移不删除旧 notes；重复执行会复用稳定主键并覆盖同一 Bookmark。
  static int migrateLegacyNotes({
    required Iterable<NoteSnapshot> notes,
    required Iterable<Book> books,
  }) => migrateLegacyNoteSnapshots(notes: notes, books: books);

  static int _timeForSnapshot(NoteSnapshot note) {
    final parsed = DateTime.tryParse(note.createdAt)?.millisecondsSinceEpoch;
    if (parsed != null && parsed > 0) return parsed;
    return 1000000000000 + _stableHash(note.id);
  }

  static int _stableHash(String value) {
    var hash = 2166136261;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash;
  }

  static String _signature({
    required String bookId,
    required int chapterIndex,
    required int chapterPos,
    required String chapterName,
    required String bookText,
  }) =>
      '$bookId\u0000$chapterIndex\u0000$chapterPos\u0000$chapterName\u0000$bookText';
}
