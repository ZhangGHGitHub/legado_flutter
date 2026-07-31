import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/obsidian/obsidian_export_port.dart';
import 'package:legado_flutter/features/obsidian/obsidian_export_dialog.dart';

class _FakeObsidianExportPort implements ObsidianExportPort {
  var loadCalls = 0;
  var saveCalls = 0;

  @override
  bool isNoteEngineReady = true;

  @override
  Future<ObsidianExportPrefs> load() async {
    loadCalls++;
    return ObsidianExportPrefs(
      method: ObsidianExportMethod.restApi,
      apiUrl: 'http://localhost:27123/vault/',
      apiKey: 'token',
      vaultPath: 'Notes',
      autoExport: true,
    );
  }

  @override
  Future<void> save(ObsidianExportPrefs prefs) async {
    saveCalls++;
  }

  @override
  Future<int> testConnection({required String url, String apiKey = ''}) async =>
      200;

  @override
  Future<String> exportLocal({
    String? bookId,
    required String localPath,
    required String vaultPath,
  }) async => '已导出到本地';

  @override
  Future<String> exportRestApi({
    String? bookId,
    required String url,
    required String vaultPath,
    String apiKey = '',
  }) async => '已通过 REST API 导出（HTTP 204）';
}

void main() {
  testWidgets('loads configuration through the Obsidian application port', (
    tester,
  ) async {
    final port = _FakeObsidianExportPort();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ObsidianExportDialog(port: port)),
      ),
    );
    await tester.pumpAndSettle();

    expect(port.loadCalls, 1);
    expect(find.text('导出到 Obsidian'), findsOneWidget);
    expect(find.text('Obsidian REST API'), findsOneWidget);
    expect(find.text('API URL'), findsOneWidget);
    expect(find.text('添加想法后自动导出'), findsOneWidget);
  });

  testWidgets('exports through the injected port and persists settings', (
    tester,
  ) async {
    final port = _FakeObsidianExportPort();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ObsidianExportDialog(port: port)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, '导出'));
    await tester.pumpAndSettle();

    expect(port.saveCalls, 1);
    expect(find.text('已通过 REST API 导出（HTTP 204）'), findsWidgets);
  });
}
