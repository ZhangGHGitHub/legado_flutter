import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/obsidian/obsidian_export_port.dart';
import 'package:legado_flutter/application/preferences/shared_preferences_runtime.dart';
import 'package:legado_flutter/domain/annotation/note_snapshot.dart';
import 'package:legado_flutter/domain/ports/application_http_request_port.dart';
import 'package:legado_flutter/domain/ports/note_port.dart';
import 'package:legado_flutter/infrastructure/obsidian/obsidian_export_port_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeNotePort implements NotePort {
  _FakeNotePort({this.available = true});

  final bool available;
  String? requestedBookId;

  @override
  bool get isAvailable => available;

  @override
  List<NoteSnapshot> list({String? bookId}) => const [];

  @override
  void save({
    required String id,
    required String bookId,
    required String chapterTitle,
    required String selectedText,
    required String noteContent,
    required int position,
    required int chapterPos,
  }) {}

  @override
  void delete(String id) {}

  @override
  String exportMarkdown({String? bookId}) {
    requestedBookId = bookId;
    return '# 笔记';
  }
}

class _RequestCall {
  const _RequestCall({
    required this.url,
    required this.method,
    required this.headers,
    required this.body,
    required this.policy,
  });

  final String url;
  final String method;
  final Map<String, String> headers;
  final String body;
  final ApplicationHttpPolicy policy;
}

class _FakeHttpPort implements ApplicationHttpRequestPort {
  final calls = <_RequestCall>[];
  ApplicationHttpResponse response = const ApplicationHttpResponse(
    statusCode: 204,
    body: '',
  );

  @override
  Future<ApplicationHttpResponse> send({
    required String url,
    required String method,
    Map<String, String> headers = const {},
    String body = '',
    int timeoutSeconds = 30,
    required ApplicationHttpPolicy policy,
  }) async {
    calls.add(
      _RequestCall(
        url: url,
        method: method,
        headers: Map.of(headers),
        body: body,
        policy: policy,
      ),
    );
    return response;
  }
}

void main() {
  tearDown(SharedPreferencesRuntime.resetForTest);

  test('reads and writes the existing Obsidian preference keys', () async {
    SharedPreferences.setMockInitialValues({
      'obsidian_export_method': 'api',
      'obsidian_api_url': 'http://localhost:27123/vault/',
      'obsidian_api_key': 'token',
      'obsidian_local_path': 'C:/vault',
      'obsidian_vault_path': 'Notes',
      'obsidian_auto_export': true,
    });
    final adapter = ObsidianExportPortAdapter(
      notePort: _FakeNotePort(),
      httpPort: _FakeHttpPort(),
    );

    final loaded = await adapter.load();
    expect(loaded.method, ObsidianExportMethod.restApi);
    expect(loaded.apiUrl, 'http://localhost:27123/vault/');
    expect(loaded.apiKey, 'token');
    expect(loaded.localPath, 'C:/vault');
    expect(loaded.vaultPath, 'Notes');
    expect(loaded.autoExport, isTrue);

    await adapter.save(
      ObsidianExportPrefs(
        method: ObsidianExportMethod.localFile,
        apiUrl: 'http://127.0.0.1:27123/vault/',
        apiKey: 'new-token',
        localPath: 'D:/vault',
        vaultPath: 'Legado',
        autoExport: false,
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('obsidian_export_method'), 'local');
    expect(
      prefs.getString('obsidian_api_url'),
      'http://127.0.0.1:27123/vault/',
    );
    expect(prefs.getString('obsidian_api_key'), 'new-token');
    expect(prefs.getString('obsidian_local_path'), 'D:/vault');
    expect(prefs.getString('obsidian_vault_path'), 'Legado');
    expect(prefs.getBool('obsidian_auto_export'), isFalse);
  });

  test('exports note markdown to the requested local vault path', () async {
    final root = await Directory.systemTemp.createTemp('legado-obsidian-');
    addTearDown(() => root.delete(recursive: true));
    final notePort = _FakeNotePort();
    final adapter = ObsidianExportPortAdapter(
      notePort: notePort,
      httpPort: _FakeHttpPort(),
    );

    final result = await adapter.exportLocal(
      bookId: 'book-1',
      localPath: root.path,
      vaultPath: 'Notes/Legado',
    );

    expect(result, startsWith('已导出到 '));
    expect(notePort.requestedBookId, 'book-1');
    final files = root.listSync(recursive: true).whereType<File>().toList();
    expect(files, hasLength(1));
    expect(await files.single.readAsString(), '# 笔记');
    expect(files.single.path, contains('${Platform.pathSeparator}Notes'));
  });

  test('uses the application HTTP port for Obsidian REST export', () async {
    final http = _FakeHttpPort();
    final adapter = ObsidianExportPortAdapter(
      notePort: _FakeNotePort(),
      httpPort: http,
    );

    expect(
      await adapter.exportRestApi(
        bookId: 'book-2',
        url: ' http://127.0.0.1:27123/vault/ ',
        vaultPath: '/Notes/Legado/',
        apiKey: ' token ',
      ),
      '已通过 REST API 导出（HTTP 204）',
    );
    final call = http.calls.single;
    expect(
      call.url,
      'http://127.0.0.1:27123/vault/Notes/Legado/legado_notes.md',
    );
    expect(call.method, 'PUT');
    expect(call.body, '# 笔记');
    expect(call.headers, {
      'Content-Type': 'text/markdown',
      'Authorization': 'Bearer token',
    });
    expect(call.policy, ApplicationHttpPolicy.localNetwork);
  });

  test('does not export when the note engine is unavailable', () async {
    final http = _FakeHttpPort();
    final adapter = ObsidianExportPortAdapter(
      notePort: _FakeNotePort(available: false),
      httpPort: http,
    );

    expect(adapter.isNoteEngineReady, isFalse);
    expect(
      await adapter.exportRestApi(
        url: 'http://localhost:27123/vault/',
        vaultPath: '',
      ),
      '暂无想法可导出',
    );
    expect(http.calls, isEmpty);
  });
}
