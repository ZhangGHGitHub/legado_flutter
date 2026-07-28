class NoteSnapshot {
  const NoteSnapshot({
    required this.id,
    required this.bookId,
    required this.chapterTitle,
    required this.selectedText,
    required this.noteContent,
    required this.position,
    required this.chapterPos,
    required this.createdAt,
  });

  final String id;
  final String bookId;
  final String chapterTitle;
  final String selectedText;
  final String noteContent;
  final int position;
  final int chapterPos;
  final String createdAt;
}
