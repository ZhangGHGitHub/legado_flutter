import '../../application/annotation/note_editor_port.dart';
import '../../services/note_service.dart';

/// Exposes the existing note save and error handling semantics to the editor.
final class NoteEditorPortAdapter implements NoteEditorPort {
  const NoteEditorPortAdapter();

  @override
  bool get isAvailable => NoteService.isReady;

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
    NoteService.save(
      id: id,
      bookId: bookId,
      chapterTitle: chapterTitle,
      selectedText: selectedText,
      noteContent: noteContent,
      position: position,
      chapterPos: chapterPos,
    );
  }
}
