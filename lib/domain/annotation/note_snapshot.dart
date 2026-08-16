import 'package:freezed_annotation/freezed_annotation.dart';

part 'note_snapshot.freezed.dart';

@freezed
class NoteSnapshot with _$NoteSnapshot {
  const factory NoteSnapshot({
    required String id,
    required String bookId,
    required String chapterTitle,
    required String selectedText,
    required String noteContent,
    required int position,
    required int chapterPos,
    required String createdAt,
  }) = _NoteSnapshot;
}
