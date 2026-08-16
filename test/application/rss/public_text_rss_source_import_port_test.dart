import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/rss/public_text_rss_source_import_port.dart';
import 'package:legado_flutter/domain/ports/public_text_fetch_port.dart';

final class _FakePublicTextFetchPort implements PublicTextFetchPort {
  _FakePublicTextFetchPort({this.result = '', this.error});

  final String result;
  final Object? error;
  String? requestedUrl;

  @override
  Future<String> fetch(String url, {String userAgent = ''}) async {
    requestedUrl = url;
    if (error != null) throw error!;
    return result;
  }
}

void main() {
  test('通过统一公开文本端口读取并清理 URL 空白', () async {
    final textPort = _FakePublicTextFetchPort(result: '[{"sourceUrl":"x"}]');
    final port = PublicTextRssSourceImportPort(textPort);

    expect(
      await port.fetch('  https://example.com/rss.json  '),
      '[{"sourceUrl":"x"}]',
    );
    expect(textPort.requestedUrl, 'https://example.com/rss.json');
  });

  test('统一文本端口失败时保持可空失败契约', () async {
    final port = PublicTextRssSourceImportPort(
      _FakePublicTextFetchPort(error: StateError('offline')),
    );

    expect(await port.fetch('https://example.com/rss.json'), isNull);
  });

  test('私有地址在调用统一文本端口前被拒绝', () async {
    final textPort = _FakePublicTextFetchPort(result: 'unexpected');
    final port = PublicTextRssSourceImportPort(textPort);

    expect(
      () => port.fetch('http://127.0.0.1/rss.json'),
      throwsA(isA<FormatException>()),
    );
    expect(textPort.requestedUrl, isNull);
  });
}
