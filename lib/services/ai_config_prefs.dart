import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// AI 记忆条目 — 对齐 Jingshiro `AiMemoryItem`
class AiMemoryItem {
  final int id;
  final String chapterRange;
  final String content;
  final String? messagesJson;

  const AiMemoryItem({
    required this.id,
    required this.chapterRange,
    required this.content,
    this.messagesJson,
  });

  String get preview {
    if (content.length <= 15) return content;
    return '${content.substring(0, 15)}...';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'chapterRange': chapterRange,
        'content': content,
        if (messagesJson != null) 'messagesJson': messagesJson,
      };

  factory AiMemoryItem.fromJson(Map<String, dynamic> json) {
    return AiMemoryItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      chapterRange: json['chapterRange']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      messagesJson: json['messagesJson']?.toString(),
    );
  }
}

/// AI 配置 — 对齐 Jingshiro `AiConfig`
class AiConfigPrefs {
  static const _kApiUrl = 'ai_api_url';
  static const _kApiKey = 'ai_api_key';
  static const _kModel = 'ai_model';
  static const _kPersona = 'ai_persona';
  static const _kMemory = 'ai_memory';
  static const _kAiAvatar = 'ai_avatar';
  static const _kUserAvatar = 'user_avatar';
  static const _kToolEnabled = 'ai_tool_enabled';

  static const defaultApiUrl = 'https://api.openai.com/v1/chat/completions';
  static const defaultModel = 'gpt-3.5-turbo';
  static const defaultPersona =
      '你是一个擅长解读文学作品的 AI 助手，熟悉用户提供的电子书和当前阅读章节内容，回答用户的问题。如果用户没有特别指定，尽量简洁清楚。';

  String apiUrl;
  String apiKey;
  String model;
  String persona;
  String aiAvatar;
  String userAvatar;
  bool toolEnabled;
  List<AiMemoryItem> memoryList;

  AiConfigPrefs({
    this.apiUrl = defaultApiUrl,
    this.apiKey = '',
    this.model = defaultModel,
    this.persona = defaultPersona,
    this.aiAvatar = '',
    this.userAvatar = '',
    this.toolEnabled = true,
    this.memoryList = const [],
  });

  static Future<AiConfigPrefs> load() async {
    final p = await SharedPreferences.getInstance();
    final rawMem = p.getString(_kMemory) ?? '';
    var memories = <AiMemoryItem>[];
    if (rawMem.trim().isNotEmpty) {
      try {
        if (rawMem.trimLeft().startsWith('[')) {
          final list = jsonDecode(rawMem) as List;
          memories = list
              .whereType<Map>()
              .map((e) => AiMemoryItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        } else {
          memories = [
            AiMemoryItem(
              id: 0,
              chapterRange: '未知章节',
              content: rawMem,
            ),
          ];
        }
      } catch (_) {
        memories = [
          AiMemoryItem(id: 0, chapterRange: '未知章节', content: rawMem),
        ];
      }
    }
    return AiConfigPrefs(
      apiUrl: p.getString(_kApiUrl) ?? defaultApiUrl,
      apiKey: p.getString(_kApiKey) ?? '',
      model: p.getString(_kModel) ?? defaultModel,
      persona: p.getString(_kPersona) ?? defaultPersona,
      aiAvatar: p.getString(_kAiAvatar) ?? '',
      userAvatar: p.getString(_kUserAvatar) ?? '',
      toolEnabled: p.getBool(_kToolEnabled) ?? true,
      memoryList: memories,
    );
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kApiUrl, apiUrl);
    await p.setString(_kApiKey, apiKey);
    await p.setString(_kModel, model);
    await p.setString(_kPersona, persona);
    await p.setString(_kAiAvatar, aiAvatar);
    await p.setString(_kUserAvatar, userAvatar);
    await p.setBool(_kToolEnabled, toolEnabled);
    await p.setString(
      _kMemory,
      jsonEncode(memoryList.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> clearMemory() async {
    memoryList = [];
    await save();
  }
}
