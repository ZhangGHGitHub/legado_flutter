import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/infrastructure/source_management/source_management_book_source_port_adapter.dart';

import '../../helpers/book_source_service_test_factory.dart';

void main() {
  test('fetchSourcesFromUrl delegates URL and result unchanged', () async {
    final service = _RecordingBookSourceService();
    final adapter = SourceManagementBookSourcePortAdapter(
      sourceService: service,
    );

    final result = await adapter.fetchSourcesFromUrl(
      ' https://share.example/sources?group=A ',
    );

    expect(service.fetchedUrl, ' https://share.example/sources?group=A ');
    expect(result, same(service.fetchedSources));
  });

  test('search delegates source, keyword and result unchanged', () async {
    final service = _RecordingBookSourceService();
    final adapter = SourceManagementBookSourcePortAdapter(
      sourceService: service,
    );
    final source = BookSource(
      bookSourceUrl: 'https://source.example',
      bookSourceName: '测试书源',
    );

    final result = await adapter.search(source, ' 关键词 ');

    expect(service.searchedSource, same(source));
    expect(service.searchedKeyword, ' 关键词 ');
    expect(result, same(service.searchResults));
  });

  test(
    'resultsToBooks delegates result maps, source URL and books unchanged',
    () {
      final service = _RecordingBookSourceService();
      final adapter = SourceManagementBookSourcePortAdapter(
        sourceService: service,
      );
      final results = <Map<String, String>>[
        {
          'name': '测试书',
          'author': '测试作者',
          'url': 'https://source.example/book/1',
        },
      ];

      final books = adapter.resultsToBooks(results, ' source-key ');

      expect(service.mappedResults, same(results));
      expect(service.mappedSourceUrl, ' source-key ');
      expect(books, same(service.mappedBooks));
    },
  );
}

final class _RecordingBookSourceService extends TestBookSourceService {
  final fetchedSources = <BookSource>[
    BookSource(
      bookSourceUrl: 'https://imported.example',
      bookSourceName: '导入书源',
    ),
  ];
  final searchResults = <Map<String, String>>[
    {
      'name': '搜索结果',
      'author': '作者',
      'url': 'https://source.example/book/search-result',
    },
  ];
  final mappedBooks = <Book>[Book(id: 'mapped-book', name: '已映射书籍')];

  String? fetchedUrl;
  BookSource? searchedSource;
  String? searchedKeyword;
  List<Map<String, String>>? mappedResults;
  String? mappedSourceUrl;

  @override
  Future<List<BookSource>> fetchSourcesFromUrl(String url) async {
    fetchedUrl = url;
    return fetchedSources;
  }

  @override
  Future<List<Map<String, String>>> search(
    BookSource source,
    String keyword,
  ) async {
    searchedSource = source;
    searchedKeyword = keyword;
    return searchResults;
  }

  @override
  List<Book> resultsToBooks(
    List<Map<String, String>> results,
    String sourceUrl,
  ) {
    mappedResults = results;
    mappedSourceUrl = sourceUrl;
    return mappedBooks;
  }
}
