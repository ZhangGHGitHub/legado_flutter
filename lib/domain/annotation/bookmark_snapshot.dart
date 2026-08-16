import 'package:freezed_annotation/freezed_annotation.dart';

part 'bookmark_snapshot.freezed.dart';

/// Pure Dart representation of an independent bookmark.
///
/// The snapshot is deliberately kept free of FRB/Rust types so bookmark
/// persistence can be replaced or tested without loading the engine.
@freezed
class BookmarkSnapshot with _$BookmarkSnapshot {
  const factory BookmarkSnapshot({
    required int time,
    required String bookId,
    required String bookName,
    required String bookAuthor,
    required int chapterIndex,
    required int chapterPos,
    required String chapterName,
    required String bookText,
    required String content,
  }) = _BookmarkSnapshot;
}
