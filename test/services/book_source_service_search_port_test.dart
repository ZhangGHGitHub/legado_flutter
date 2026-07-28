import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/book_source_search_port.dart';
import 'package:legado_flutter/models/book_source.dart';
import 'package:legado_flutter/services/book_source_service.dart';

class _FakeBookSourceSearchPort implements BookSourceSearchPort {
  BookSource? source;
  String? keyword;

  @override
  Future<List<Map<String, String>>> search(
    BookSource value,
    String query,
  ) async {
    source = value;
    keyword = query;
    return [
      {'name': '测试书', 'author': '测试作者', 'url': 'https://source.example/book/1'},
    ];
  }
}

void main() {
  test('BookSourceService search uses the injected engine port', () async {
    final port = _FakeBookSourceSearchPort();
    final service = BookSourceService(searchPort: port);
    final source = BookSource(
      bookSourceUrl: 'https://source.example',
      bookSourceName: '测试书源',
    );

    final results = await service.search(source, '关键词');

    expect(port.source, same(source));
    expect(port.keyword, '关键词');
    expect(results.single['name'], '测试书');
  });
}
