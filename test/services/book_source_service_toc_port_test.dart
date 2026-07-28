import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/book_source_book_info_port.dart';
import 'package:legado_flutter/domain/ports/book_source_toc_port.dart';
import 'package:legado_flutter/models/book.dart';
import 'package:legado_flutter/models/book_source.dart';
import 'package:legado_flutter/models/chapter.dart';
import 'package:legado_flutter/services/book_source_service.dart';
import 'package:legado_flutter/utils/site_busy_guard.dart';

class _FakeBookInfoPort implements BookSourceBookInfoPort {
  final tocUrl = 'https://source.example/book/1/chapters';
  int calls = 0;

  @override
  Future<Map<String, String>> getBookInfo(
    BookSource source,
    String bookUrl,
  ) async {
    calls++;
    return {'tocUrl': tocUrl};
  }
}

class _FakeTocPort implements BookSourceTocPort {
  _FakeTocPort({this.waitForRelease = false});

  final bool waitForRelease;
  final started = Completer<void>();
  final release = Completer<void>();
  BookSource? source;
  Book? book;
  int calls = 0;

  @override
  Future<List<Chapter>> getToc(BookSource value, Book input) async {
    calls++;
    source = value;
    book = input;
    if (!started.isCompleted) started.complete();
    if (waitForRelease) await release.future;
    return [
      Chapter(
        id: 'chapter-0',
        bookId: input.id,
        title: '第一章',
        index: 0,
        url: 'https://source.example/chapter/1',
      ),
      Chapter(
        id: 'chapter-1',
        bookId: input.id,
        title: '第二章',
        index: 1,
        url: 'https://source.example/chapter/2',
      ),
    ];
  }
}

void main() {
  setUp(SiteBusyGuard.debugReset);
  tearDown(SiteBusyGuard.debugReset);

  test('BookSourceService getChapters uses the injected TOC port', () async {
    final infoPort = _FakeBookInfoPort();
    final tocPort = _FakeTocPort();
    final service = BookSourceService(bookInfoPort: infoPort, tocPort: tocPort);
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

    final chapters = await service.getChapters(book, source: source);

    expect(tocPort.source, same(source));
    expect(infoPort.calls, 1);
    expect(tocPort.calls, 1);
    expect(tocPort.book?.sourceUrl, 'https://source.example/book/1/chapters');
    expect(tocPort.book?.id, book.id);
    expect(chapters.map((chapter) => chapter.title), ['第一章', '第二章']);
    expect(chapters.map((chapter) => chapter.index), [0, 1]);
  });

  test('getChapters uses book tocUrl without querying book info', () async {
    final infoPort = _FakeBookInfoPort();
    final tocPort = _FakeTocPort();
    final service = BookSourceService(bookInfoPort: infoPort, tocPort: tocPort);
    final source = BookSource(
      bookSourceUrl: 'https://source.example',
      bookSourceName: '测试书源',
    );
    final book = Book(
      id: 'book-with-toc-url',
      name: '测试书',
      sourceUrl: 'https://source.example/book/1',
      tocUrl: 'https://source.example/book/1/saved-toc',
      bookSourceUrl: source.bookSourceUrl,
    );

    final chapters = await service.getChapters(book, source: source);

    expect(infoPort.calls, 0);
    expect(tocPort.calls, 1);
    expect(tocPort.book?.sourceUrl, 'https://source.example/book/1/saved-toc');
    expect(chapters.map((chapter) => chapter.title), ['第一章', '第二章']);
    expect(chapters.map((chapter) => chapter.index), [0, 1]);
  });

  test('concurrent getChapters calls share one TOC port request', () async {
    final infoPort = _FakeBookInfoPort();
    final tocPort = _FakeTocPort(waitForRelease: true);
    final service = BookSourceService(bookInfoPort: infoPort, tocPort: tocPort);
    final source = BookSource(
      bookSourceUrl: 'https://source.example',
      bookSourceName: '测试书源',
    );
    final book = Book(
      id: 'book-deduped',
      name: '测试书',
      sourceUrl: 'https://source.example/book/1',
      tocUrl: 'https://source.example/book/1/saved-toc',
      bookSourceUrl: source.bookSourceUrl,
    );

    final first = service.getChapters(book, source: source);
    await tocPort.started.future;
    final second = service.getChapters(book, source: source);

    expect(tocPort.calls, 1);
    expect(infoPort.calls, 0);
    tocPort.release.complete();
    final results = await Future.wait([first, second]);
    expect(results[0].map((chapter) => chapter.index), [0, 1]);
    expect(results[1].map((chapter) => chapter.index), [0, 1]);
  });
}
