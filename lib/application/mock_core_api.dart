import '../domain/book/book.dart';
import '../domain/search_result_item.dart';
import 'core_api.dart';

/// Rust-free implementation for UI development and contract tests.
class MockCoreApi implements CoreApi {
  MockCoreApi({List<Book>? books}) : books = books ?? _defaultBooks;

  final List<Book> books;

  static final _defaultBooks = <Book>[
    Book(id: 'mock-book-1', name: '示例书籍', author: '示例作者'),
  ];

  @override
  Future<List<Book>> getBookshelf() async => List.unmodifiable(books);

  @override
  Future<List<SearchResultItem>> searchBooks({
    required String sourceUrl,
    required String keyword,
  }) async {
    if (keyword.trim().isEmpty) {
      return const [];
    }
    return const [
      SearchResultItem(
        name: '示例搜索结果',
        author: '示例作者',
        bookUrl: 'https://example.invalid/book/1',
      ),
    ];
  }
}
