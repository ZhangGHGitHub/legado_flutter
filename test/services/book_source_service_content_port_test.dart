import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/book_source_content_port.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import '../helpers/book_source_service_test_factory.dart';

class _FakeBookSourceContentPort implements BookSourceContentPort {
  BookSource? source;
  String? chapterUrl;

  @override
  Future<String> getContent(BookSource value, String url) async {
    source = value;
    chapterUrl = url;
    return '第一行\r\n第二行\n第三行';
  }
}

void main() {
  test(
    'BookSourceService getChapterContent uses the injected content port',
    () async {
      final port = _FakeBookSourceContentPort();
      final service = createTestBookSourceService(contentPort: port);
      final source = BookSource(
        bookSourceUrl: 'https://source.example',
        bookSourceName: '测试书源',
      );

      final content = await service.getChapterContent(
        'https://source.example/chapter/1',
        source: source,
      );

      expect(port.source, same(source));
      expect(port.chapterUrl, 'https://source.example/chapter/1');
      expect(content, '第一行\r\n第二行\n第三行');
    },
  );
}
