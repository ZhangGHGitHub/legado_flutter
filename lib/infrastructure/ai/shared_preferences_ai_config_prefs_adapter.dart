import '../../application/ai/ai_config_prefs_port.dart';
import '../../services/ai_config_prefs.dart' as service;

/// 使用既有键名、JSON 格式和默认值保存 AI 配置的适配器。
final class SharedPreferencesAiConfigPrefsAdapter implements AiConfigPrefsPort {
  const SharedPreferencesAiConfigPrefsAdapter();

  @override
  Future<AiConfigSettings> load() async {
    final settings = await service.AiConfigPrefs.load();
    return _toSettings(settings);
  }

  @override
  Future<void> save(AiConfigSettings settings) async {
    await _toService(settings).save();
  }

  @override
  Future<void> clearMemory() async {
    final settings = await service.AiConfigPrefs.load();
    await settings.clearMemory();
  }

  static AiConfigSettings _toSettings(service.AiConfigPrefs settings) {
    return AiConfigSettings(
      apiUrl: settings.apiUrl,
      apiKey: settings.apiKey,
      model: settings.model,
      persona: settings.persona,
      aiAvatar: settings.aiAvatar,
      userAvatar: settings.userAvatar,
      toolEnabled: settings.toolEnabled,
      memoryList: settings.memoryList.map(_toMemory).toList(growable: false),
    );
  }

  static service.AiConfigPrefs _toService(AiConfigSettings settings) {
    return service.AiConfigPrefs(
      apiUrl: settings.apiUrl,
      apiKey: settings.apiKey,
      model: settings.model,
      persona: settings.persona,
      aiAvatar: settings.aiAvatar,
      userAvatar: settings.userAvatar,
      toolEnabled: settings.toolEnabled,
      memoryList: settings.memoryList.map(_toServiceMemory).toList(),
    );
  }

  static AiMemoryItem _toMemory(service.AiMemoryItem item) {
    return AiMemoryItem(
      id: item.id,
      chapterRange: item.chapterRange,
      content: item.content,
      messagesJson: item.messagesJson,
    );
  }

  static service.AiMemoryItem _toServiceMemory(AiMemoryItem item) {
    return service.AiMemoryItem(
      id: item.id,
      chapterRange: item.chapterRange,
      content: item.content,
      messagesJson: item.messagesJson,
    );
  }
}
