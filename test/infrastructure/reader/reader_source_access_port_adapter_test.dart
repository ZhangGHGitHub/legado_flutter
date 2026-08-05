import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/infrastructure/reader/reader_source_access_port_adapter.dart';

void main() {
  test('书源访问适配器转发书源快照和自动换源参数', () async {
    const book = Book(id: 'book-1', name: '测试书');
    const source = BookSource(
      bookSourceUrl: 'https://source.example',
      bookSourceName: '测试书源',
    );
    Book? foundBook;
    List<BookSource>? receivedSources;
    int? receivedConcurrency;
    final adapter = ReaderSourceAccessPortAdapter(
      sourceForBook: (received) {
        foundBook = received;
        return source;
      },
      availableSources: () => [source],
      autoChangeSource: (received, {required sources, concurrency = 4}) async {
        foundBook = received;
        receivedSources = sources;
        receivedConcurrency = concurrency;
        return received;
      },
    );

    expect(adapter.sourceForBook(book), same(source));
    final sources = adapter.availableSources;
    expect(sources, [source]);
    expect(() => sources.add(source), throwsUnsupportedError);
    final result = await adapter.autoChangeSource(
      book,
      sources: sources,
      concurrency: 2,
    );

    expect(foundBook, same(book));
    expect(receivedSources, same(sources));
    expect(receivedConcurrency, 2);
    expect(result, same(book));
  });
}
