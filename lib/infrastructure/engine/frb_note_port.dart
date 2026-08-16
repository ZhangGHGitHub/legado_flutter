import '../../bridge/legado_db_bridge.dart';
import '../../bridge/legado_engine_bridge.dart';
import '../../domain/annotation/note_snapshot.dart';
import '../../domain/ports/note_port.dart';
import '../../src/rust/api.dart' as rust_api;

class FrbNotePort implements NotePort {
  @override
  bool get isAvailable =>
      LegadoEngineBridge.isAvailable && LegadoDbBridge.isReady;

  @override
  List<NoteSnapshot> list({String? bookId}) {
    if (!isAvailable) return const [];
    return rust_api
        .listNotes(bookId: bookId ?? '')
        .map(_fromGenerated)
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
    if (!isAvailable) return;
    rust_api.upsertNote(
      id: id,
      bookId: bookId,
      chapterTitle: chapterTitle,
      selectedText: selectedText,
      noteContent: noteContent,
      position: position,
      chapterPos: chapterPos,
    );
  }

  @override
  void delete(String id) {
    if (!isAvailable) return;
    rust_api.deleteNote(id: id);
  }

  @override
  String exportMarkdown({String? bookId}) {
    if (!isAvailable) return '';
    return rust_api.exportNotesMarkdown(bookId: bookId ?? '');
  }

  static NoteSnapshot _fromGenerated(rust_api.NoteDto note) {
    return NoteSnapshot(
      id: note.id,
      bookId: note.bookId,
      chapterTitle: note.chapterTitle,
      selectedText: note.selectedText,
      noteContent: note.noteContent,
      position: note.position,
      chapterPos: note.chapterPos,
      createdAt: note.createdAt,
    );
  }
}
