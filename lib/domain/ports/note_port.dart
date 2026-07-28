import '../annotation/note_snapshot.dart';

abstract interface class NotePort {
  bool get isAvailable;

  List<NoteSnapshot> list({String? bookId});

  void save({
    required String id,
    required String bookId,
    required String chapterTitle,
    required String selectedText,
    required String noteContent,
    required int position,
    required int chapterPos,
  });

  void delete(String id);

  String exportMarkdown({String? bookId});
}
