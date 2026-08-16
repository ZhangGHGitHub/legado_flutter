import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/annotation/bookmark_snapshot.dart';
import 'package:legado_flutter/domain/annotation/note_snapshot.dart';

void main() {
  group('BookmarkSnapshot', () {
    const bookmark = BookmarkSnapshot(
      time: 1720000000000,
      bookId: 'book-id',
      bookName: 'Book name',
      bookAuthor: 'Author',
      chapterIndex: 7,
      chapterPos: 42,
      chapterName: 'Chapter',
      bookText: 'Excerpt',
      content: 'Note',
    );

    test('preserves all legacy constructor fields', () {
      expect(bookmark.time, 1720000000000);
      expect(bookmark.bookId, 'book-id');
      expect(bookmark.bookName, 'Book name');
      expect(bookmark.bookAuthor, 'Author');
      expect(bookmark.chapterIndex, 7);
      expect(bookmark.chapterPos, 42);
      expect(bookmark.chapterName, 'Chapter');
      expect(bookmark.bookText, 'Excerpt');
      expect(bookmark.content, 'Note');
    });

    test('uses value equality and copyWith without mutating the original', () {
      expect(bookmark, equals(bookmark.copyWith()));

      final updated = bookmark.copyWith(content: 'Updated note');

      expect(updated.content, 'Updated note');
      expect(updated.bookId, bookmark.bookId);
      expect(bookmark.content, 'Note');
    });
  });

  group('NoteSnapshot', () {
    const note = NoteSnapshot(
      id: 'note-id',
      bookId: 'book-id',
      chapterTitle: 'Chapter',
      selectedText: 'Selected text',
      noteContent: 'Note content',
      position: 9,
      chapterPos: 42,
      createdAt: '2026-08-02T08:00:00Z',
    );

    test('preserves all legacy constructor fields', () {
      expect(note.id, 'note-id');
      expect(note.bookId, 'book-id');
      expect(note.chapterTitle, 'Chapter');
      expect(note.selectedText, 'Selected text');
      expect(note.noteContent, 'Note content');
      expect(note.position, 9);
      expect(note.chapterPos, 42);
      expect(note.createdAt, '2026-08-02T08:00:00Z');
    });

    test('uses value equality and copyWith without mutating the original', () {
      expect(note, equals(note.copyWith()));

      final updated = note.copyWith(noteContent: 'Updated content');

      expect(updated.noteContent, 'Updated content');
      expect(updated.id, note.id);
      expect(note.noteContent, 'Note content');
    });
  });
}
