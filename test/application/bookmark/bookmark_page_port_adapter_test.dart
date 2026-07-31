import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/annotation/bookmark_snapshot.dart';
import 'package:legado_flutter/domain/annotation/note_snapshot.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/ports/bookmark_port.dart';
import 'package:legado_flutter/domain/ports/note_port.dart';
import 'package:legado_flutter/infrastructure/bookmark/bookmark_page_port_adapter.dart';
import 'package:legado_flutter/services/bookmark_service.dart';
import 'package:legado_flutter/services/note_service.dart';

void main() {
  late _FakeBookmarkPort bookmarkPort;
  late _FakeNotePort notePort;

  setUp(() {
    bookmarkPort = _FakeBookmarkPort();
    notePort = _FakeNotePort();
    BookmarkService.configureBookmarkPort(bookmarkPort);
    NoteService.configureNotePort(notePort);
  });

  tearDown(() {
    BookmarkService.resetBookmarkPort();
    NoteService.resetNotePort();
  });

  test(
    'loads migrated legacy bookmarks and ordinary notes at one boundary',
    () {
      notePort.items.addAll([
        const NoteSnapshot(
          id: 'legacy-bookmark',
          bookId: 'book-1',
          chapterTitle: '第一章',
          selectedText: '旧正文',
          noteContent: '书签 · 第1页',
          position: 0,
          chapterPos: -1,
          createdAt: '2026-07-22 12:00:00',
        ),
        const NoteSnapshot(
          id: 'thought-1',
          bookId: 'book-1',
          chapterTitle: '第二章',
          selectedText: '正文',
          noteContent: '想法',
          position: 1,
          chapterPos: 8,
          createdAt: '2026-07-22 12:01:00',
        ),
      ]);

      final snapshot = const BookmarkPagePortAdapter().load(
        books: [Book(id: 'book-1', name: '测试书', author: '测试作者')],
      );

      expect(snapshot.marks, hasLength(2));
      final bookmark = snapshot.marks.singleWhere((mark) => mark.isBookmark);
      expect(bookmark.bookName, '测试书');
      expect(bookmark.bookAuthor, '测试作者');
      expect(bookmark.chapterPos, 0);
      expect(
        snapshot.marks.singleWhere((mark) => !mark.isBookmark).noteContent,
        '想法',
      );
      expect(bookmarkPort.items, hasLength(1));
    },
  );

  test('delegates JSON import/export and delete operations', () {
    const raw = '''[
      {
        "time": 123,
        "bookId": "book-1",
        "bookName": "测试书",
        "bookAuthor": "作者",
        "chapterIndex": 2,
        "chapterPos": 9,
        "chapterName": "第三章",
        "bookText": "正文",
        "content": "备注"
      }
    ]''';
    final port = const BookmarkPagePortAdapter();

    expect(port.importJson(raw), 1);
    expect(port.exportJson(), contains('"time": 123'));
    expect(port.deleteBookmark(123), isTrue);
    expect(bookmarkPort.items, isEmpty);

    notePort.items.add(
      const NoteSnapshot(
        id: 'note-1',
        bookId: 'book-1',
        chapterTitle: '第一章',
        selectedText: '正文',
        noteContent: '想法',
        position: 0,
        chapterPos: 1,
        createdAt: '2026-07-22 12:00:00',
      ),
    );
    expect(port.deleteNote('note-1'), isTrue);
    expect(notePort.items, isEmpty);
  });
}

final class _FakeBookmarkPort implements BookmarkPort {
  final items = <BookmarkSnapshot>[];

  @override
  bool get isAvailable => true;

  @override
  List<BookmarkSnapshot> list({String? bookId}) => items
      .where((bookmark) => bookId == null || bookmark.bookId == bookId)
      .toList(growable: false);

  @override
  bool save(BookmarkSnapshot bookmark) {
    items.removeWhere((item) => item.time == bookmark.time);
    items.add(bookmark);
    return true;
  }

  @override
  bool delete(int time) {
    final before = items.length;
    items.removeWhere((item) => item.time == time);
    return items.length != before;
  }
}

final class _FakeNotePort implements NotePort {
  final items = <NoteSnapshot>[];

  @override
  bool get isAvailable => true;

  @override
  List<NoteSnapshot> list({String? bookId}) => items
      .where((note) => bookId == null || note.bookId == bookId)
      .toList(growable: false);

  @override
  void save({
    required String id,
    required String bookId,
    required String chapterTitle,
    required String selectedText,
    required String noteContent,
    required int position,
    required int chapterPos,
  }) {}

  @override
  void delete(String id) => items.removeWhere((note) => note.id == id);

  @override
  String exportMarkdown({String? bookId}) => '';
}
