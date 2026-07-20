import 'dart:async';

import '../bridge/legado_db_bridge.dart';
import '../bridge/legado_engine_bridge.dart';
import 'app_log.dart';
import '../src/rust/api.dart' as rust_api;

/// 想法笔记服务（Phase 4.5）
class NoteService {
  static bool get isReady =>
      LegadoEngineBridge.isAvailable && LegadoDbBridge.isReady;

  static List<rust_api.NoteDto> list({String? bookId}) {
    if (!isReady) return [];
    try {
      return rust_api.listNotes(bookId: bookId ?? '');
    } catch (e) {
      unawaited(AppLog.e('NoteService.list: $e'));
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
    int chapterPos = -1,
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
        chapterPos: chapterPos,
      );
    } catch (e) {
      unawaited(AppLog.e('NoteService.save: $e'));
    }
  }

  static void delete(String id) {
    if (!isReady) return;
    try {
      rust_api.deleteNote(id: id);
    } catch (e) {
      unawaited(AppLog.e('NoteService.delete: $e'));
    }
  }

  static String exportMarkdown({String? bookId}) {
    if (!isReady) return '';
    try {
      return rust_api.exportNotesMarkdown(bookId: bookId ?? '');
    } catch (e) {
      unawaited(AppLog.e('NoteService.exportMarkdown: $e'));
      return '';
    }
  }
}
