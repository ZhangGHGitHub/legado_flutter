import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/annotation/note_snapshot.dart';
import '../domain/ports/note_port.dart';
import '../infrastructure/engine/frb_note_port.dart';
import 'app_log.dart';

/// 想法笔记服务（Phase 4.5）
class NoteService {
  static NotePort _notePort = FrbNotePort();

  @visibleForTesting
  static void configureNotePort(NotePort port) {
    _notePort = port;
  }

  @visibleForTesting
  static void resetNotePort() {
    _notePort = FrbNotePort();
  }

  static bool get isReady => _notePort.isAvailable;

  static List<NoteSnapshot> list({String? bookId}) {
    if (!isReady) return [];
    try {
      return _notePort.list(bookId: bookId);
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
      _notePort.save(
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
      _notePort.delete(id);
    } catch (e) {
      unawaited(AppLog.e('NoteService.delete: $e'));
    }
  }

  static String exportMarkdown({String? bookId}) {
    if (!isReady) return '';
    try {
      return _notePort.exportMarkdown(bookId: bookId);
    } catch (e) {
      unawaited(AppLog.e('NoteService.exportMarkdown: $e'));
      return '';
    }
  }
}
