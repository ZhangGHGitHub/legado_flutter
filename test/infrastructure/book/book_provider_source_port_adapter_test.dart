import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/infrastructure/book/book_provider_source_port_adapter.dart';

import '../../helpers/book_source_service_test_factory.dart';

void main() {
  test(
    'delegates BookProvider source operations without changing values',
    () async {
      final service = _RecordingBookSourceService();
      final adapter = BookProviderSourcePortAdapter(sourceService: service);
      final source = BookSource(
        bookSourceUrl: 'https://source.example',
        bookSourceName: '测试书源',
      );
      final book = Book(
        id: 'book-1',
        name: '测试书',
        sourceUrl: 'https://source.example/book/1',
        bookSourceUrl: source.bookSourceUrl,
      );
      final results = <Map<String, String>>[
        {'name': '结果书', 'url': 'https://source.example/book/result'},
      ];

      expect(
        await adapter.getBookInfo(source, ' https://book.example/info '),
        same(service.bookInfo),
      );
      expect(
        await adapter.search(source, ' 关键词 '),
        same(service.searchResults),
      );
      expect(
        adapter.resultsToBooks(results, ' source-key '),
        same(service.books),
      );
      expect(
        await adapter.getChapters(book, source: source),
        same(service.chapters),
      );

      expect(service.infoSource, same(source));
      expect(service.infoUrl, ' https://book.example/info ');
      expect(service.searchSource, same(source));
      expect(service.searchKeyword, ' 关键词 ');
      expect(service.mappedResults, same(results));
      expect(service.mappedSourceUrl, ' source-key ');
      expect(service.chaptersBook, same(book));
      expect(service.chaptersSource, same(source));
    },
  );

  test(
    'delegates both reader content capabilities including next URL',
    () async {
      final service = _RecordingBookSourceService();
      final adapter = BookProviderSourcePortAdapter(sourceService: service);
      final source = BookSource(
        bookSourceUrl: 'https://source.example',
        bookSourceName: '测试书源',
      );

      expect(
        await adapter.getChapterContent(
          'https://source.example/chapter/1',
          source: source,
        ),
        'raw-content',
      );
      expect(
        await adapter.getChapterContentWithNextChapter(
          'https://source.example/chapter/1',
          source: source,
          nextChapterUrl: 'https://source.example/chapter/2',
        ),
        'paginated-content',
      );

      expect(service.contentUrl, 'https://source.example/chapter/1');
      expect(service.contentSource, same(source));
      expect(service.paginatedUrl, 'https://source.example/chapter/1');
      expect(service.paginatedSource, same(source));
      expect(service.nextChapterUrl, 'https://source.example/chapter/2');
    },
  );
}

final class _RecordingBookSourceService extends TestBookSourceService {
  final bookInfo = {'name': '详情'};
  final searchResults = <Map<String, String>>[
    {'name': '搜索结果', 'url': 'https://source.example/search'},
  ];
  final books = <Book>[Book(id: 'mapped', name: '映射书')];
  final chapters = <Chapter>[
    Chapter(
      id: 'chapter-1',
      bookId: 'book-1',
      title: '第一章',
      index: 0,
      url: 'https://source.example/chapter/1',
    ),
  ];

  BookSource? infoSource;
  String? infoUrl;
  BookSource? searchSource;
  String? searchKeyword;
  List<Map<String, String>>? mappedResults;
  String? mappedSourceUrl;
  Book? chaptersBook;
  BookSource? chaptersSource;
  String? contentUrl;
  BookSource? contentSource;
  String? paginatedUrl;
  BookSource? paginatedSource;
  String? nextChapterUrl;

  @override
  Future<Map<String, String>> getBookInfo(
    BookSource source,
    String bookUrl,
  ) async {
    infoSource = source;
    infoUrl = bookUrl;
    return bookInfo;
  }

  @override
  Future<List<Map<String, String>>> search(
    BookSource source,
    String keyword,
  ) async {
    searchSource = source;
    searchKeyword = keyword;
    return searchResults;
  }

  @override
  List<Book> resultsToBooks(
    List<Map<String, String>> results,
    String sourceUrl,
  ) {
    mappedResults = results;
    mappedSourceUrl = sourceUrl;
    return books;
  }

  @override
  Future<List<Chapter>> getChapters(
    Book book, {
    required BookSource source,
  }) async {
    chaptersBook = book;
    chaptersSource = source;
    return chapters;
  }

  @override
  Future<String> getChapterContent(
    String url, {
    required BookSource source,
  }) async {
    contentUrl = url;
    contentSource = source;
    return 'raw-content';
  }

  @override
  Future<String> getChapterContentWithNextChapter(
    String url, {
    required BookSource source,
    String? nextChapterUrl,
  }) async {
    paginatedUrl = url;
    paginatedSource = source;
    this.nextChapterUrl = nextChapterUrl;
    return 'paginated-content';
  }
}
