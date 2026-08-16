import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/domain/ports/reader_content_source_port.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/infrastructure/reader/reader_content_refetch_port_adapter.dart';

void main() {
  final book = Book(id: 'book-1', name: '测试书');
  final chapter = Chapter(
    id: 'chapter-1',
    bookId: 'book-1',
    title: '第一章',
    index: 0,
    url: 'https://example.com/chapter-1',
  );

  test(
    'returns empty content when the book source cannot be resolved',
    () async {
      final contentSource = _FakeReaderContentSource();
      final port = ReaderContentRefetchPortAdapter(
        contentSource: contentSource,
        resolveSource: (_) => null,
      );

      expect(await port.fetchRawContent(book: book, chapter: chapter), isEmpty);
      expect(contentSource.requests, isEmpty);
    },
  );

  test('delegates the chapter URL and resolved source unchanged', () async {
    final contentSource = _FakeReaderContentSource();
    final source = BookSource(
      bookSourceUrl: 'https://example.com',
      bookSourceName: '测试源',
    );
    final port = ReaderContentRefetchPortAdapter(
      contentSource: contentSource,
      resolveSource: (_) => source,
    );

    expect(await port.fetchRawContent(book: book, chapter: chapter), '原始正文');
    expect(contentSource.requests, [(chapter.url, source)]);
  });
}

final class _FakeReaderContentSource implements ReaderContentSourcePort {
  final requests = <(String, BookSource)>[];

  @override
  Future<String> getChapterContent(
    String url, {
    required BookSource source,
  }) async {
    requests.add((url, source));
    return '原始正文';
  }
}
