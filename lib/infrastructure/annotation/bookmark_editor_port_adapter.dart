import '../../application/annotation/bookmark_editor_port.dart';
import '../../services/bookmark_service.dart';

/// Exposes the existing bookmark save and timestamp semantics to the editor.
final class BookmarkEditorPortAdapter implements BookmarkEditorPort {
  const BookmarkEditorPortAdapter();

  @override
  bool get isAvailable => BookmarkService.isReady;

  @override
  int? save({
    int? time,
    required String bookId,
    required String bookName,
    required String bookAuthor,
    required int chapterIndex,
    required int chapterPos,
    required String chapterName,
    required String bookText,
    String content = '',
  }) => BookmarkService.save(
    time: time,
    bookId: bookId,
    bookName: bookName,
    bookAuthor: bookAuthor,
    chapterIndex: chapterIndex,
    chapterPos: chapterPos,
    chapterName: chapterName,
    bookText: bookText,
    content: content,
  );
}
