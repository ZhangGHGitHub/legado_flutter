import '../../services/obsidian_export_prefs.dart' show ObsidianExportPrefs;

export '../../services/obsidian_export_prefs.dart'
    show ObsidianExportMethod, ObsidianExportPrefs;

/// Obsidian 导出对话框所需的应用边界。
abstract interface class ObsidianExportPort {
  bool get isNoteEngineReady;

  Future<ObsidianExportPrefs> load();

  Future<void> save(ObsidianExportPrefs prefs);

  Future<int> testConnection({required String url, String apiKey = ''});

  Future<String> exportLocal({
    String? bookId,
    required String localPath,
    required String vaultPath,
  });

  Future<String> exportRestApi({
    String? bookId,
    required String url,
    required String vaultPath,
    String apiKey = '',
  });
}
