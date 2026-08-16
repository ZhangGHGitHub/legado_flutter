import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/annotation/note_snapshot.dart';
import 'package:legado_flutter/domain/ports/note_port.dart';
import 'package:legado_flutter/infrastructure/annotation/note_editor_port_adapter.dart';
import 'package:legado_flutter/services/note_service.dart';

void main() {
  late _MemoryNotePort notePort;

  setUp(() {
    notePort = _MemoryNotePort();
    NoteService.configureNotePort(notePort);
  });

  tearDown(NoteService.resetNotePort);

  test('delegates note editor fields to the existing note service', () {
    const adapter = NoteEditorPortAdapter();

    adapter.save(
      id: 'note-1',
      bookId: 'book-1',
      chapterTitle: '第一章',
      selectedText: '正文',
      noteContent: '想法',
      position: 3,
      chapterPos: 44,
    );

    expect(notePort.saved, isNotNull);
    expect(notePort.saved!.id, 'note-1');
    expect(notePort.saved!.bookId, 'book-1');
    expect(notePort.saved!.chapterTitle, '第一章');
    expect(notePort.saved!.selectedText, '正文');
    expect(notePort.saved!.noteContent, '想法');
    expect(notePort.saved!.position, 3);
    expect(notePort.saved!.chapterPos, 44);
  });

  test('reports the existing note service readiness gate', () {
    const adapter = NoteEditorPortAdapter();
    expect(adapter.isAvailable, isTrue);

    notePort.isAvailable = false;
    expect(adapter.isAvailable, isFalse);
  });
}

final class _MemoryNotePort implements NotePort {
  @override
  bool isAvailable = true;
  NoteSnapshot? saved;

  @override
  List<NoteSnapshot> list({String? bookId}) => const [];

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
    saved = NoteSnapshot(
      id: id,
      bookId: bookId,
      chapterTitle: chapterTitle,
      selectedText: selectedText,
      noteContent: noteContent,
      position: position,
      chapterPos: chapterPos,
      createdAt: '',
    );
  }

  @override
  void delete(String id) {}

  @override
  String exportMarkdown({String? bookId}) => '';
}
