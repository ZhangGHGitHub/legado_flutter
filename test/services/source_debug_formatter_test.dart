import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/book_source_debug_port.dart';
import 'package:legado_flutter/services/source_debug_formatter.dart';

void main() {
  test('formatDebugLog includes steps and results', () {
    const result = BookSourceDebugSnapshot(
      requestUrl: 'http://test/search?q=斗破',
      requestMethod: 'GET',
      responseStatus: '200',
      responseCharset: 'UTF-8',
      responseSize: 1024,
      responseBodyPreview: '<html>test</html>',
      ruleSteps: [
        BookSourceDebugStep(
          step: 'HTTP 响应',
          rule: 'url',
          result: 'status=200',
          ok: true,
        ),
      ],
      results: [
        BookSourceDebugItem(
          name: '斗破苍穹',
          author: '土豆',
          coverUrl: '',
          bookUrl: 'http://test/book/1',
          kind: '',
          note: '',
        ),
      ],
    );

    final log = formatDebugLog(result);
    expect(log, contains('斗破苍穹'));
    expect(log, contains('HTTP 响应'));
    expect(log, contains('status=200'));
    expect(log, contains('<html>test</html>'));
  });
}
