import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/services/app_paths.dart';
import 'package:legado_flutter/services/note_export_service.dart';
import 'package:legado_flutter/src/rust/api.dart' as rust_api;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;

  setUp(() async {
    tempRoot = Directory.systemTemp.createTempSync('legado_note_export_');
    SharedPreferences.setMockInitialValues({
      AppDataPrefs.dataDirKey: tempRoot.path,
    });
  });

  tearDown(() {
    if (tempRoot.existsSync()) {
      tempRoot.deleteSync(recursive: true);
    }
  });

  test('exportPerNoteFiles writes markdown files', () async {
    const notes = [
      rust_api.NoteDto(
        id: 'n1',
        bookId: 'b1',
        chapterTitle: '第一章',
        selectedText: '选中片段',
        noteContent: '我的想法',
        position: 0,
        createdAt: '2026-07-11',
      ),
    ];

    final paths = await NoteExportService.exportPerNoteFiles(notes);
    expect(paths, hasLength(1));
    expect(await File(paths.first).exists(), isTrue);
    final content = await File(paths.first).readAsString();
    expect(content, contains('> 选中片段'));
    expect(content, contains('我的想法'));
    expect(paths.first, contains('notes_export'));
  });
}
