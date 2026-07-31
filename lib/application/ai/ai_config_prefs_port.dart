/// AI 配置与对话记忆的应用层持久化边界。
abstract interface class AiConfigPrefsPort {
  Future<AiConfigSettings> load();

  Future<void> save(AiConfigSettings settings);

  Future<void> clearMemory();
}

/// AI 配置页当前生效的设置。
final class AiConfigSettings {
  static const defaultApiUrl = 'https://api.openai.com/v1/chat/completions';
  static const defaultModel = 'gpt-3.5-turbo';
  static const defaultPersona =
      '你是一个擅长解读文学作品的 AI 助手，熟悉用户提供的电子书和当前阅读章节内容，回答用户的问题。如果用户没有特别指定，尽量简洁清楚。';

  const AiConfigSettings({
    this.apiUrl = defaultApiUrl,
    this.apiKey = '',
    this.model = defaultModel,
    this.persona = defaultPersona,
    this.aiAvatar = '',
    this.userAvatar = '',
    this.toolEnabled = true,
    this.memoryList = const [],
  });

  final String apiUrl;
  final String apiKey;
  final String model;
  final String persona;
  final String aiAvatar;
  final String userAvatar;
  final bool toolEnabled;
  final List<AiMemoryItem> memoryList;

  AiConfigSettings copyWith({
    String? apiUrl,
    String? apiKey,
    String? model,
    String? persona,
    String? aiAvatar,
    String? userAvatar,
    bool? toolEnabled,
    List<AiMemoryItem>? memoryList,
  }) {
    return AiConfigSettings(
      apiUrl: apiUrl ?? this.apiUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      persona: persona ?? this.persona,
      aiAvatar: aiAvatar ?? this.aiAvatar,
      userAvatar: userAvatar ?? this.userAvatar,
      toolEnabled: toolEnabled ?? this.toolEnabled,
      memoryList: memoryList ?? this.memoryList,
    );
  }
}

/// AI 对话记忆条目。
final class AiMemoryItem {
  const AiMemoryItem({
    required this.id,
    required this.chapterRange,
    required this.content,
    this.messagesJson,
  });

  final int id;
  final String chapterRange;
  final String content;
  final String? messagesJson;

  String get preview {
    if (content.length <= 15) return content;
    return '${content.substring(0, 15)}...';
  }
}
