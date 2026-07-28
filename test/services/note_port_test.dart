import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/annotation/note_snapshot.dart';
import 'package:legado_flutter/domain/ports/note_port.dart';
import 'package:legado_flutter/services/note_service.dart';

class _FakeNotePort implements NotePort {
  final notes = <String, NoteSnapshot>{};
  final calls = <String>[];

  @override
  bool get isAvailable => true;

  @override
  List<NoteSnapshot> list({String? bookId}) {
    calls.add('list:${bookId ?? ''}');
    return notes.values
        .where((note) => bookId == null || note.bookId == bookId)
        .toList(growable: false);
  }

  @override
  void save({
    required String id,
    required String bookId,
    required String chapterTitle,
    required String selectedText,
    required String noteContent,
    required int position,
    required int chapterPos,
  }) {
    calls.add('save:$id');
    notes[id] = NoteSnapshot(
      id: id,
      bookId: bookId,
      chapterTitle: chapterTitle,
      selectedText: selectedText,
      noteContent: noteContent,
      position: position,
      chapterPos: chapterPos,
      createdAt: '2026-01-01',
    );
  }

  @override
  void delete(String id) {
    calls.add('delete:$id');
    notes.remove(id);
  }

  @override
  String exportMarkdown({String? bookId}) {
    calls.add('export:${bookId ?? ''}');
    return '# notes';
  }
}

void main() {
  late _FakeNotePort port;

  setUp(() {
    port = _FakeNotePort();
    NoteService.configureNotePort(port);
  });

  tearDown(NoteService.resetNotePort);

  test('NoteService forwards all note operations through the port', () {
    NoteService.save(
      id: 'n1',
      bookId: 'b1',
      chapterTitle: '第一章',
      selectedText: '原文',
      noteContent: '想法',
      position: 2,
      chapterPos: 10,
    );

    expect(NoteService.list(bookId: 'b1').single.noteContent, '想法');
    expect(NoteService.exportMarkdown(bookId: 'b1'), '# notes');
    NoteService.delete('n1');
    expect(NoteService.list(bookId: 'b1'), isEmpty);
    expect(port.calls, [
      'save:n1',
      'list:b1',
      'export:b1',
      'delete:n1',
      'list:b1',
    ]);
  });
}
