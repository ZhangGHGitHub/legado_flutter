import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/infrastructure/book/book_info_chapter_port_adapter.dart';

void main() {
  test('forwards directory state and loading options to callbacks', () async {
    const book = Book(id: 'book-1', name: '测试书');
    const source = BookSource(
      bookSourceUrl: 'https://source.example',
      bookSourceName: '测试书源',
    );
    const chapter = Chapter(
      id: 'chapter-1',
      bookId: 'book-1',
      title: '第一章',
      index: 0,
      url: 'https://source.example/chapter-1',
    );
    var loading = false;
    var refreshing = true;
    Book? loadedBook;
    BookSource? loadedSource;
    bool? loadedForceRefresh;

    final adapter = BookInfoChapterPortAdapter(
      currentChapters: () => [chapter],
      isLoading: () => loading,
      isRefreshingToc: () => refreshing,
      loadChapters: (book, {required source, forceRefresh = false}) async {
        loadedBook = book;
        loadedSource = source;
        loadedForceRefresh = forceRefresh;
      },
    );

    expect(adapter.currentChapters, [chapter]);
    expect(adapter.isLoading, isFalse);
    expect(adapter.isRefreshingToc, isTrue);

    loading = true;
    refreshing = false;
    await adapter.loadChapters(book, source: source, forceRefresh: true);

    expect(adapter.isLoading, isTrue);
    expect(adapter.isRefreshingToc, isFalse);
    expect(loadedBook, book);
    expect(loadedSource, source);
    expect(loadedForceRefresh, isTrue);
  });
}
