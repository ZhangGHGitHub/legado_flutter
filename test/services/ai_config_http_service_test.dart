import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/application_http_request_port.dart';
import 'package:legado_flutter/services/ai_config_http_service.dart';

class _RequestCall {
  const _RequestCall({
    required this.url,
    required this.method,
    required this.headers,
    required this.body,
    required this.timeoutSeconds,
    required this.policy,
  });

  final String url;
  final String method;
  final Map<String, String> headers;
  final String body;
  final int timeoutSeconds;
  final ApplicationHttpPolicy policy;
}

class _FakeHttpPort implements ApplicationHttpRequestPort {
  ApplicationHttpResponse response = const ApplicationHttpResponse(
    statusCode: 200,
    body: '',
  );
  final calls = <_RequestCall>[];

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
        timeoutSeconds: timeoutSeconds,
        policy: policy,
      ),
    );
    return response;
  }
}

void main() {
  test('modelsEndpoint keeps the existing OpenAI-compatible mapping', () {
    expect(
      AiConfigHttpService.modelsEndpoint(
        ' https://example.com/v1/chat/completions ',
      ),
      'https://example.com/v1/models',
    );
    expect(
      AiConfigHttpService.modelsEndpoint('https://example.com/v1/'),
      'https://example.com/v1/models',
    );
    expect(
      AiConfigHttpService.modelsEndpoint('https://example.com/v1'),
      'https://example.com/v1/models',
    );
  });

  test(
    'fetchModels uses the public Rust request port and parses ids',
    () async {
      final port = _FakeHttpPort()
        ..response = const ApplicationHttpResponse(
          statusCode: 200,
          body: '{"data":[{"id":"model-b"},{"id":"model-a"},{}]}',
        );
      final service = AiConfigHttpService(port);

      expect(
        await service.fetchModels(
          apiUrl: ' https://example.com/v1/chat/completions ',
          apiKey: ' secret ',
        ),
        ['model-b', 'model-a'],
      );
      final call = port.calls.single;
      expect(call.url, 'https://example.com/v1/models');
      expect(call.method, 'GET');
      expect(call.headers, {'Authorization': 'Bearer secret'});
      expect(call.body, isEmpty);
      expect(call.timeoutSeconds, 20);
      expect(call.policy, ApplicationHttpPolicy.publicOnly);
    },
  );

  test('fetchModels keeps malformed or non-list responses empty', () async {
    final port = _FakeHttpPort();
    final service = AiConfigHttpService(port);

    port.response = const ApplicationHttpResponse(
      statusCode: 200,
      body: 'not-json',
    );
    expect(
      await service.fetchModels(apiUrl: 'https://example.com/v1'),
      isEmpty,
    );

    port.response = const ApplicationHttpResponse(
      statusCode: 200,
      body: '{"data":{}}',
    );
    expect(
      await service.fetchModels(apiUrl: 'https://example.com/v1'),
      isEmpty,
    );
  });

  test('fetchModels preserves the previous non-success failure', () async {
    final port = _FakeHttpPort()
      ..response = const ApplicationHttpResponse(
        statusCode: 401,
        body: '{"data":[{"id":"must-not-be-used"}]}',
      );

    expect(
      () => AiConfigHttpService(
        port,
      ).fetchModels(apiUrl: 'https://example.com/v1'),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('HTTP 401'),
        ),
      ),
    );
  });

  test(
    'testModel sends the existing JSON payload and returns status',
    () async {
      final port = _FakeHttpPort()
        ..response = const ApplicationHttpResponse(
          statusCode: 429,
          body: '{"error":"rate limited"}',
        );
      final service = AiConfigHttpService(port);

      expect(
        await service.testModel(
          apiUrl: ' https://example.com/v1/chat/completions ',
          model: ' model-a ',
          apiKey: ' secret ',
        ),
        429,
      );
      final call = port.calls.single;
      expect(call.url, 'https://example.com/v1/chat/completions');
      expect(call.method, 'POST');
      expect(call.headers, {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer secret',
      });
      expect(jsonDecode(call.body), {
        'model': 'model-a',
        'messages': [
          {'role': 'user', 'content': 'ping'},
        ],
        'max_tokens': 8,
      });
      expect(call.timeoutSeconds, 30);
      expect(call.policy, ApplicationHttpPolicy.publicOnly);
    },
  );
}
