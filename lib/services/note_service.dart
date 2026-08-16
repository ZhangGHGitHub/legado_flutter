import 'dart:async';

import 'package:flutter/foundation.dart';

import '../application/diagnostics/app_log_port.dart';
import '../domain/annotation/note_snapshot.dart';
import '../domain/ports/note_port.dart';

/// 想法笔记服务（Phase 4.5）
class NoteService {
  static NotePort? _configuredNotePort;
  static AppLogPort? _configuredAppLogPort;

  static NotePort get _notePort =>
      _configuredNotePort ?? (throw StateError('NoteService 尚未配置 NotePort'));

  static void configureNotePort(NotePort port) {
    _configuredNotePort = port;
  }

  static void configureAppLogPort(AppLogPort port) {
    _configuredAppLogPort = port;
  }

  @visibleForTesting
  static void resetNotePort() {
    _configuredNotePort = null;
  }

  @visibleForTesting
  static void resetAppLogPort() {
    _configuredAppLogPort = null;
  }

  static bool get isReady => _configuredNotePort?.isAvailable ?? false;

  static List<NoteSnapshot> list({String? bookId}) {
    if (!isReady) return [];
    try {
      return _notePort.list(bookId: bookId);
    } catch (e) {
      unawaited(_configuredAppLogPort?.e('NoteService.list: $e'));
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
      unawaited(_configuredAppLogPort?.e('NoteService.save: $e'));
    }
  }

  static void delete(String id) {
    if (!isReady) return;
    try {
      _notePort.delete(id);
    } catch (e) {
      unawaited(_configuredAppLogPort?.e('NoteService.delete: $e'));
    }
  }

  static String exportMarkdown({String? bookId}) {
    if (!isReady) return '';
    try {
      return _notePort.exportMarkdown(bookId: bookId);
    } catch (e) {
      unawaited(_configuredAppLogPort?.e('NoteService.exportMarkdown: $e'));
      return '';
    }
  }
}
