import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/services/http_tts_service.dart';

void main() {
  test('resolves GET placeholders with encoded speech text', () {
    const config = HttpTtsConfig(
      url: 'https://tts.example/audio?text={{speakText}}&speed={{speed}}',
    );

    final request = config.resolve('你好 世界', 1.25);
    expect(request.method, 'GET');
    expect(
      request.url,
      contains('text=%E4%BD%A0%E5%A5%BD%20%E4%B8%96%E7%95%8C'),
    );
    expect(request.url, endsWith('&speed=1.25'));
  });

  test('resolves AnalyzeUrl style POST body and headers', () {
    const config = HttpTtsConfig(
      url:
          'https://tts.example/audio,{"method":"POST","body":"text={{speakText}}","headers":{"X-Test":"ok"}}',
      contentType: 'application/x-www-form-urlencoded',
    );

    final request = config.resolve('测试', 1.0);
    expect(request.method, 'POST');
    expect(request.body, 'text=测试');
    expect(request.headers['X-Test'], 'ok');
    expect(
      request.headers['Content-Type'],
      'application/x-www-form-urlencoded',
    );
  });
}
