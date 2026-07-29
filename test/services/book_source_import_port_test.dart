import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/public_text_fetch_port.dart';
import '../helpers/book_source_service_test_factory.dart';

class _FakePublicTextFetchPort implements PublicTextFetchPort {
  _FakePublicTextFetchPort(this.body);

  final String body;
  String? requestedUrl;

  @override
  Future<String> fetch(String url, {String userAgent = ''}) async {
    requestedUrl = url;
    return body;
  }
}

void main() {
  test('book source URL import fetches through the injected port', () async {
    final port = _FakePublicTextFetchPort('''
      {"data":[{"bookSourceUrl":"https://source.example","bookSourceName":"示例书源"}]}
    ''');

    final sources = await createTestBookSourceService(
      publicTextPort: port,
    ).fetchSourcesFromUrl('https://share.example/sources');

    expect(port.requestedUrl, 'https://share.example/sources');
    expect(sources, hasLength(1));
    expect(sources.single.bookSourceUrl, 'https://source.example');
    expect(sources.single.bookSourceName, '示例书源');
  });

  test('book source URL import keeps invalid response behavior', () async {
    final port = _FakePublicTextFetchPort('地址不存在');

    final sources = await createTestBookSourceService(
      publicTextPort: port,
    ).fetchSourcesFromUrl('https://share.example/expired');

    expect(sources, isEmpty);
  });
}
