import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/public_text_fetch_port.dart';
import 'package:legado_flutter/services/rule_sub_import_service.dart';

void main() {
  test('fetchText delegates JSON text unchanged to the network port', () async {
    final port = _FakePublicTextFetchPort(
      response: '{\n  "name": "规则",\n  "enabled": true\n}',
    );

    final text = await RuleSubImportService.fetchText(
      'https://rules.example/sub.json',
      fetchPort: port,
    );

    expect(text, '{\n  "name": "规则",\n  "enabled": true\n}');
    expect(port.urls, ['https://rules.example/sub.json']);
    expect(port.userAgents, ['']);
  });

  test('fetchText preserves requestWithoutUA marker semantics', () async {
    final port = _FakePublicTextFetchPort(response: '[]');

    final text = await RuleSubImportService.fetchText(
      'https://rules.example/sub.json#requestWithoutUA',
      fetchPort: port,
    );

    expect(text, '[]');
    expect(port.urls, ['https://rules.example/sub.json']);
    expect(port.userAgents, ['null']);
  });

  test(
    'fetchText rejects private initial URLs before invoking the port',
    () async {
      final port = _FakePublicTextFetchPort(response: '[]');

      await expectLater(
        RuleSubImportService.fetchText(
          'http://127.0.0.1/private.json',
          fetchPort: port,
        ),
        throwsA(isA<FormatException>()),
      );
      expect(port.urls, isEmpty);
    },
  );

  test(
    'fetchText propagates redirect SSRF failures from the network port',
    () async {
      final port = _FakePublicTextFetchPort(
        error: const FormatException('禁止访问内网/私有地址（SSRF 防护）'),
      );

      await expectLater(
        RuleSubImportService.fetchText(
          'https://rules.example/start.json',
          fetchPort: port,
        ),
        throwsA(isA<FormatException>()),
      );
    },
  );
}

class _FakePublicTextFetchPort implements PublicTextFetchPort {
  _FakePublicTextFetchPort({this.response = '', this.error});

  final String response;
  final Object? error;
  final List<String> urls = [];
  final List<String> userAgents = [];

  @override
  Future<String> fetch(String url, {String userAgent = ''}) async {
    urls.add(url);
    userAgents.add(userAgent);
    if (error case final Object error) throw error;
    return response;
  }
}
