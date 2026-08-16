import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/cache/cache_book_download_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/infrastructure/cache/cache_book_download_port_adapter.dart';

void main() {
  test('adapter forwards state, commands, and change notifications', () async {
    final changes = ChangeNotifier();
    final book = const Book(id: 'book-1', name: '测试书');
    final chapter = const Chapter(
      id: 'chapter-1',
      bookId: 'book-1',
      title: '第一章',
      index: 0,
      url: 'https://source.example/book/1/1',
    );
    final source = const BookSource(
      bookSourceUrl: 'https://source.example',
      bookSourceName: '测试书源',
    );
    var state = const CacheBookDownloadState(
      isDownloading: true,
      downloadBookId: 'book-1',
      completed: 2,
      total: 5,
    );
    var cancelCalls = 0;
    Book? loadedBook;
    BookSource? loadedSource;
    String? downloadedBookId;
    List<Chapter>? downloadedChapters;
    BookSource? downloadedSource;
    int? downloadConcurrency;
    var notifications = 0;

    final adapter = CacheBookDownloadPortAdapter(
      changes: changes,
      state: () => state,
      loadChapters: (book, {required source}) async {
        loadedBook = book;
        loadedSource = source;
        return [chapter];
      },
      downloadAllChapters: (bookId, chapters, source, {concurrency = 1}) async {
        downloadedBookId = bookId;
        downloadedChapters = chapters;
        downloadedSource = source;
        downloadConcurrency = concurrency;
      },
      cancelDownload: () {
        cancelCalls++;
      },
    );
    void listener() => notifications++;
    adapter.addListener(listener);
    changes.notifyListeners();

    expect(adapter.state, state);
    expect(adapter.state.progress, 0.4);
    final chapterSnapshot = await adapter.loadChapters(book, source: source);
    expect(chapterSnapshot, [chapter]);
    expect(() => chapterSnapshot.add(chapter), throwsUnsupportedError);
    await adapter.downloadAllChapters(
      book.id,
      [chapter],
      source,
      concurrency: 3,
    );
    adapter.cancelDownload();

    expect(notifications, 1);
    expect(loadedBook, book);
    expect(loadedSource, source);
    expect(downloadedBookId, book.id);
    expect(downloadedChapters, [chapter]);
    expect(downloadedSource, source);
    expect(downloadConcurrency, 3);
    expect(cancelCalls, 1);

    state = const CacheBookDownloadState();
    expect(adapter.state.isDownloading, isFalse);
    adapter.removeListener(listener);
    changes.dispose();
  });
}
