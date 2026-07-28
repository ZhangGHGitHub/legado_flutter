import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/book_source_book_info_port.dart';
import 'package:legado_flutter/models/book_source.dart';
import 'package:legado_flutter/services/book_source_service.dart';

class _FakeBookSourceBookInfoPort implements BookSourceBookInfoPort {
  BookSource? source;
  String? bookUrl;

  @override
  Future<Map<String, String>> getBookInfo(BookSource value, String url) async {
    source = value;
    bookUrl = url;
    return {
      'name': '测试详情',
      'author': '测试作者',
      'tocUrl': 'https://source.example/book/1/toc',
    };
  }
}

void main() {
  test('BookSourceService getBookInfo uses the injected engine port', () async {
    final port = _FakeBookSourceBookInfoPort();
    final service = BookSourceService(bookInfoPort: port);
    final source = BookSource(
      bookSourceUrl: 'https://source.example',
      bookSourceName: '测试书源',
    );

    final info = await service.getBookInfo(
      source,
      'https://source.example/book/1',
    );

    expect(port.source, same(source));
    expect(port.bookUrl, 'https://source.example/book/1');
    expect(info['name'], '测试详情');
    expect(info['tocUrl'], 'https://source.example/book/1/toc');
  });
}
