import '../bridge/legado_db_bridge.dart';
import '../bridge/legado_engine_bridge.dart';
import '../src/rust/api.dart' as rust_api;

/// 想法笔记服务（Phase 4.5）
class NoteService {
  static bool get isReady =>
      LegadoEngineBridge.isAvailable && LegadoDbBridge.isReady;

  static List<rust_api.NoteDto> list({String? bookId}) {
    if (!isReady) return [];
    try {
      return rust_api.listNotes(bookId: bookId ?? '');
    } catch (_) {
      return [];
    }
  }

  static void save({
    required String id,
    required String bookId,
    required String chapterTitle,
    required String selectedText,
    required String noteContent,
    int position = 0,
  }) {
    if (!isReady) return;
    try {
      rust_api.upsertNote(
        id: id,
        bookId: bookId,
        chapterTitle: chapterTitle,
        selectedText: selectedText,
        noteContent: noteContent,
        position: position,
      );
    } catch (_) {}
  }

  static void delete(String id) {
    if (!isReady) return;
    try {
      rust_api.deleteNote(id: id);
    } catch (_) {}
  }

  static String exportMarkdown({String? bookId}) {
    if (!isReady) return '';
    try {
      return rust_api.exportNotesMarkdown(bookId: bookId ?? '');
    } catch (_) {
      return '';
    }
  }
}
