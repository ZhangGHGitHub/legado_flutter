import 'dart:io';

import 'package:path/path.dart' as p;

import '../services/app_paths.dart';
import '../src/rust/api.dart' as rust_api;
import 'note_service.dart';

/// Obsidian / 本地 Markdown 导出（Phase 4.5）
class NoteExportService {
  static Future<Directory> exportDir() async {
    final root = await AppPaths.dataRoot();
    final dir = Directory(p.join(root.path, 'notes_export'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<String> exportToLocalFiles({String? bookId}) async {
    final markdown = NoteService.exportMarkdown(bookId: bookId);
    if (markdown.isEmpty) return '';

    final dir = await exportDir();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final suffix = (bookId == null || bookId.isEmpty) ? 'all' : bookId;
    final file = File(p.join(dir.path, 'legado_notes_${suffix}_$stamp.md'));
    await file.writeAsString(markdown);
    return file.path;
  }

  static Future<List<String>> exportPerNoteFiles(List<rust_api.NoteDto> notes) async {
    final dir = await exportDir();
    final paths = <String>[];
    for (final note in notes) {
      final safeName = note.chapterTitle.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final file = File(
        p.join(dir.path, '${note.id}_$safeName.md'),
      );
      final body = StringBuffer()
        ..writeln('# ${note.chapterTitle}')
        ..writeln()
        ..writeln('> ${note.selectedText.replaceAll('\n', '\n> ')}')
        ..writeln()
        ..writeln(note.noteContent)
        ..writeln()
        ..writeln('---')
        ..writeln('created: ${note.createdAt}')
        ..writeln('bookId: ${note.bookId}');
      await file.writeAsString(body.toString());
      paths.add(file.path);
    }
    return paths;
  }
}
