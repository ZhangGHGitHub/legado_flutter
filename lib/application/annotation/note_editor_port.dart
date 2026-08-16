/// Application boundary for saving a note from the editor.
abstract interface class NoteEditorPort {
  bool get isAvailable;

  void save({
    required String id,
    required String bookId,
    required String chapterTitle,
    required String selectedText,
    required String noteContent,
    required int position,
    required int chapterPos,
  });
}

/// Used before the composition root provides the annotation adapter.
final class UnavailableNoteEditorPort implements NoteEditorPort {
  const UnavailableNoteEditorPort();

  @override
  bool get isAvailable => false;

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
}
