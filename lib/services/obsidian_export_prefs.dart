import 'package:shared_preferences/shared_preferences.dart';

enum ObsidianExportMethod { restApi, localFile }

/// Obsidian 导出配置 — 对齐 Jingshiro `dialog_obsidian_export`
class ObsidianExportPrefs {
  static const _kMethod = 'obsidian_export_method';
  static const _kApiUrl = 'obsidian_api_url';
  static const _kApiKey = 'obsidian_api_key';
  static const _kLocalPath = 'obsidian_local_path';
  static const _kVaultPath = 'obsidian_vault_path';
  static const _kAutoExport = 'obsidian_auto_export';

  ObsidianExportMethod method;
  String apiUrl;
  String apiKey;
  String localPath;
  String vaultPath;
  bool autoExport;

  ObsidianExportPrefs({
    this.method = ObsidianExportMethod.localFile,
    this.apiUrl = '',
    this.apiKey = '',
    this.localPath = '',
    this.vaultPath = '',
    this.autoExport = false,
  });

  static Future<ObsidianExportPrefs> load() async {
    final p = await SharedPreferences.getInstance();
    final methodRaw = p.getString(_kMethod) ?? 'local';
    return ObsidianExportPrefs(
      method: methodRaw == 'api'
          ? ObsidianExportMethod.restApi
          : ObsidianExportMethod.localFile,
      apiUrl: p.getString(_kApiUrl) ?? '',
      apiKey: p.getString(_kApiKey) ?? '',
      localPath: p.getString(_kLocalPath) ?? '',
      vaultPath: p.getString(_kVaultPath) ?? '',
      autoExport: p.getBool(_kAutoExport) ?? false,
    );
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _kMethod,
      method == ObsidianExportMethod.restApi ? 'api' : 'local',
    );
    await p.setString(_kApiUrl, apiUrl);
    await p.setString(_kApiKey, apiKey);
    await p.setString(_kLocalPath, localPath);
    await p.setString(_kVaultPath, vaultPath);
    await p.setBool(_kAutoExport, autoExport);
  }
}
