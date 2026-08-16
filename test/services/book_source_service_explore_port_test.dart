import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/book_source_explore_port.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import '../helpers/book_source_service_test_factory.dart';

class _FakeBookSourceExplorePort implements BookSourceExplorePort {
  BookSource? source;
  String? exploreUrl;
  int? page;

  @override
  Future<List<Map<String, String>>> explore(
    BookSource value,
    String url, {
    int page = 1,
  }) async {
    source = value;
    exploreUrl = url;
    this.page = page;
    return [
      {
        'name': '发现书',
        'author': '发现作者',
        'url': 'https://source.example/book/explore-1',
      },
    ];
  }
}

void main() {
  test('BookSourceService explore uses the injected engine port', () async {
    final port = _FakeBookSourceExplorePort();
    final service = createTestBookSourceService(explorePort: port);
    final source = BookSource(
      bookSourceUrl: 'https://source.example',
      bookSourceName: '测试书源',
    );

    final results = await service.explore(
      source,
      'https://source.example/explore',
      page: 3,
    );

    expect(port.source, same(source));
    expect(port.exploreUrl, 'https://source.example/explore');
    expect(port.page, 3);
    expect(results.single['name'], '发现书');
    expect(results.single['url'], 'https://source.example/book/explore-1');
  });
}
