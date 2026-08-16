import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/ai/ai_config_prefs_port.dart';
import 'package:legado_flutter/domain/ports/application_http_request_port.dart';
import 'package:legado_flutter/infrastructure/ai/ai_config_http_port_adapter.dart';
import 'package:legado_flutter/infrastructure/ai/shared_preferences_ai_config_prefs_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeHttpPort implements ApplicationHttpRequestPort {
  ApplicationHttpResponse response = const ApplicationHttpResponse(
    statusCode: 200,
    body: '{"data":[{"id":"model-a"}]}',
  );
  String? url;
  String? method;
  Map<String, String>? headers;
  String? body;
  int? timeoutSeconds;
  ApplicationHttpPolicy? policy;

  @override
  Future<ApplicationHttpResponse> send({
    required String url,
    required String method,
    Map<String, String> headers = const {},
    String body = '',
    int timeoutSeconds = 30,
    required ApplicationHttpPolicy policy,
  }) async {
    this.url = url;
    this.method = method;
    this.headers = Map.of(headers);
    this.body = body;
    this.timeoutSeconds = timeoutSeconds;
    this.policy = policy;
    return response;
  }
}

void main() {
  test(
    'SharedPreferences adapter preserves AI values and memory JSON',
    () async {
      SharedPreferences.setMockInitialValues({
        'ai_api_url': 'https://example.com/v1/chat/completions',
        'ai_api_key': 'old-key',
        'ai_model': 'old-model',
        'ai_persona': 'old-persona',
        'ai_avatar': 'ai.png',
        'user_avatar': 'user.png',
        'ai_tool_enabled': false,
        'ai_memory': jsonEncode([
          {
            'id': 7,
            'chapterRange': '第 1 章',
            'content': '记忆内容',
            'messagesJson': '[{}]',
          },
        ]),
      });
      final prefs = await SharedPreferences.getInstance();
      const adapter = SharedPreferencesAiConfigPrefsAdapter();

      final loaded = await adapter.load();
      expect(loaded.apiUrl, 'https://example.com/v1/chat/completions');
      expect(loaded.apiKey, 'old-key');
      expect(loaded.model, 'old-model');
      expect(loaded.persona, 'old-persona');
      expect(loaded.aiAvatar, 'ai.png');
      expect(loaded.userAvatar, 'user.png');
      expect(loaded.toolEnabled, isFalse);
      expect(loaded.memoryList.single.messagesJson, '[{}]');

      await adapter.save(
        const AiConfigSettings(
          apiUrl: 'https://example.com/v1/chat/completions',
          apiKey: 'new-key',
          model: 'new-model',
          persona: 'new-persona',
          aiAvatar: 'new-ai.png',
          userAvatar: 'new-user.png',
          toolEnabled: true,
          memoryList: [
            AiMemoryItem(id: 9, chapterRange: '第 2 章', content: '新记忆'),
          ],
        ),
      );
      expect(prefs.getString('ai_api_key'), 'new-key');
      expect(prefs.getString('ai_model'), 'new-model');
      expect(prefs.getBool('ai_tool_enabled'), isTrue);
      expect(jsonDecode(prefs.getString('ai_memory')!), [
        {'id': 9, 'chapterRange': '第 2 章', 'content': '新记忆'},
      ]);

      await adapter.clearMemory();
      expect(jsonDecode(prefs.getString('ai_memory')!), isEmpty);
      expect(prefs.getString('ai_api_key'), 'new-key');
    },
  );

  test(
    'HTTP adapter delegates model operations to the existing service',
    () async {
      final http = _FakeHttpPort();
      final adapter = AiConfigHttpPortAdapter(http);

      expect(
        await adapter.fetchModels(
          apiUrl: ' https://example.com/v1/chat/completions ',
          apiKey: ' secret ',
        ),
        ['model-a'],
      );
      expect(http.url, 'https://example.com/v1/models');
      expect(http.method, 'GET');
      expect(http.headers, {'Authorization': 'Bearer secret'});
      expect(http.timeoutSeconds, 20);
      expect(http.policy, ApplicationHttpPolicy.publicOnly);

      http.response = const ApplicationHttpResponse(statusCode: 204, body: '');
      expect(
        await adapter.testModel(
          apiUrl: ' https://example.com/v1/chat/completions ',
          model: ' model-a ',
          apiKey: ' secret ',
        ),
        204,
      );
      expect(http.url, 'https://example.com/v1/chat/completions');
      expect(http.method, 'POST');
      expect(jsonDecode(http.body!), {
        'model': 'model-a',
        'messages': [
          {'role': 'user', 'content': 'ping'},
        ],
        'max_tokens': 8,
      });
      expect(http.timeoutSeconds, 30);
      expect(http.policy, ApplicationHttpPolicy.publicOnly);
    },
  );
}
