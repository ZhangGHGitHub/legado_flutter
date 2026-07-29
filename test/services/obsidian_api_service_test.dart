import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/application_http_request_port.dart';
import 'package:legado_flutter/services/obsidian_api_service.dart';

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
  test(
    'testConnection preserves localhost access through local policy',
    () async {
      final port = _FakeHttpPort()
        ..response = const ApplicationHttpResponse(statusCode: 401, body: 'no');
      final service = ObsidianApiService(port);

      expect(
        await service.testConnection(
          url: ' http://127.0.0.1:27123/ ',
          apiKey: ' token ',
        ),
        401,
      );
      final call = port.calls.single;
      expect(call.url, 'http://127.0.0.1:27123/');
      expect(call.method, 'GET');
      expect(call.headers, {'Authorization': 'Bearer token'});
      expect(call.timeoutSeconds, 15);
      expect(call.policy, ApplicationHttpPolicy.localNetwork);
    },
  );

  test(
    'exportMarkdown replaces the path placeholder and sends markdown',
    () async {
      final port = _FakeHttpPort()
        ..response = const ApplicationHttpResponse(statusCode: 204, body: '');
      final service = ObsidianApiService(port);

      expect(
        await service.exportMarkdown(
          url: 'http://127.0.0.1:27123/vault/{path}',
          markdown: '# 标题',
          fileName: 'Notes/Legado notes.md',
          apiKey: ' token ',
        ),
        '已通过 REST API 导出（HTTP 204）',
      );
      final call = port.calls.single;
      expect(
        call.url,
        'http://127.0.0.1:27123/vault/Notes%2FLegado%20notes.md',
      );
      expect(call.method, 'PUT');
      expect(call.body, '# 标题');
      expect(call.headers, {
        'Content-Type': 'text/markdown',
        'Authorization': 'Bearer token',
      });
      expect(call.timeoutSeconds, 30);
      expect(call.policy, ApplicationHttpPolicy.localNetwork);
    },
  );

  test(
    'exportMarkdown keeps appended vault paths and reports error body',
    () async {
      final port = _FakeHttpPort()
        ..response = const ApplicationHttpResponse(
          statusCode: 409,
          body: 'conflict',
        );
      final service = ObsidianApiService(port);

      await expectLater(
        service.exportMarkdown(
          url: 'http://localhost:27123/vault/',
          markdown: 'body',
          fileName: 'Notes/legado.md',
        ),
        throwsA(
          predicate<Object>(
            (error) => error.toString().contains('HTTP 409: conflict'),
          ),
        ),
      );
      expect(
        port.calls.single.url,
        'http://localhost:27123/vault/Notes/legado.md',
      );
    },
  );
}
