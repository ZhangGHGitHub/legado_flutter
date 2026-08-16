import 'dart:io';

import 'package:path/path.dart' as p;

import '../../application/obsidian/obsidian_export_port.dart';
import '../../domain/ports/application_http_request_port.dart';
import '../../domain/ports/note_port.dart';
import '../../services/note_export_service.dart';
import '../../services/obsidian_api_service.dart';
import '../../services/obsidian_export_prefs.dart' as service;

/// 将既有 Obsidian service 组合到应用端口。
final class ObsidianExportPortAdapter implements ObsidianExportPort {
  ObsidianExportPortAdapter({
    required NotePort notePort,
    required ApplicationHttpRequestPort httpPort,
  }) : _notePort = notePort,
       _apiService = ObsidianApiService(httpPort);

  final NotePort _notePort;
  final ObsidianApiService _apiService;

  @override
  bool get isNoteEngineReady => _notePort.isAvailable;

  @override
  Future<ObsidianExportPrefs> load() => service.ObsidianExportPrefs.load();

  @override
  Future<void> save(ObsidianExportPrefs prefs) => prefs.save();

  @override
  Future<int> testConnection({required String url, String apiKey = ''}) {
    return _apiService.testConnection(url: url, apiKey: apiKey);
  }

  @override
  Future<String> exportLocal({
    String? bookId,
    required String localPath,
    required String vaultPath,
  }) async {
    final markdown = _markdown(bookId: bookId);
    if (markdown.isEmpty) return '暂无想法可导出';

    var dirPath = localPath.trim();
    if (dirPath.isEmpty) {
      final out = await NoteExportService.exportToLocalFiles(bookId: bookId);
      return out.isEmpty ? '暂无想法可导出' : '已导出到 $out';
    }
    if (vaultPath.trim().isNotEmpty) {
      dirPath = p.join(dirPath, vaultPath.trim().replaceAll('/', p.separator));
    }
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final suffix = (bookId == null || bookId.isEmpty) ? 'all' : bookId;
    final file = File(p.join(dir.path, 'legado_notes_${suffix}_$stamp.md'));
    await file.writeAsString(markdown);
    return '已导出到 ${file.path}';
  }

  @override
  Future<String> exportRestApi({
    String? bookId,
    required String url,
    required String vaultPath,
    String apiKey = '',
  }) {
    final markdown = _markdown(bookId: bookId);
    if (markdown.isEmpty) return Future.value('暂无想法可导出');
    final fileName = vaultPath.trim().isEmpty
        ? 'legado_notes.md'
        : '${vaultPath.trim().replaceAll(RegExp(r'^/+|/+$'), '')}/legado_notes.md';
    return _apiService.exportMarkdown(
      url: url.trim(),
      markdown: markdown,
      fileName: fileName,
      apiKey: apiKey,
    );
  }

  String _markdown({String? bookId}) {
    if (!isNoteEngineReady) return '';
    return _notePort.exportMarkdown(bookId: bookId);
  }
}
