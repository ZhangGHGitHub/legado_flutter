import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/reader/book_reader_prefs_port.dart';
import 'package:legado_flutter/application/reader/read_book_config_prefs_port.dart';
import 'package:legado_flutter/application/reader/reader_image_headers_port.dart';
import 'package:legado_flutter/application/reader/reader_source_presentation_port.dart';
import 'package:legado_flutter/application/reader/reader_simulated_reading_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/features/reader/reader_page.dart';
import 'package:legado_flutter/features/reader/reader_settings.dart';

import '../../helpers/fake_book_reader_prefs_port.dart';

final class _FakeReadBookConfigPrefsPort implements ReadBookConfigPrefsPort {
  @override
  Future<ReaderSettings> load({
    ReaderSettings base = const ReaderSettings(),
  }) async => base;

  @override
  Future<void> save(ReaderSettings settings) async {}
}

final class _FakeReaderImageHeadersPort implements ReaderImageHeadersPort {
  @override
  Future<Map<String, String>> imageHeadersForBook(Book book) async => const {};
}

final class _FakeReaderSourcePresentationPort
    implements ReaderSourcePresentationPort {
  @override
  String sourceNameForBook(Book book) => '测试书源';
}

void main() {
  test('test hosts can explicitly inject the book reader preference fake', () {
    final prefs = FakeBookReaderPrefsPort();
    final chapter = Chapter(
      id: 'chapter-1',
      bookId: 'book-1',
      title: '第一章',
      index: 0,
      url: '',
    );
    final page = ReaderPage(
      book: Book(id: 'book-1', name: '测试书'),
      chapter: chapter,
      allChapters: [chapter],
      prefs: prefs,
    );

    expect(page.prefs, same(prefs));
    expect(page.prefs, isA<BookReaderPrefsPort>());
  });

  test('test hosts can explicitly inject the global reader config fake', () {
    final configPrefs = _FakeReadBookConfigPrefsPort();
    final chapter = Chapter(
      id: 'chapter-1',
      bookId: 'book-1',
      title: '第一章',
      index: 0,
      url: '',
    );
    final page = ReaderPage(
      book: Book(id: 'book-1', name: '测试书'),
      chapter: chapter,
      allChapters: [chapter],
      configPrefs: configPrefs,
    );

    expect(page.configPrefs, same(configPrefs));
    expect(page.configPrefs, isA<ReadBookConfigPrefsPort>());
  });

  test('test hosts can explicitly inject the reader image headers port', () {
    final imageHeadersPort = _FakeReaderImageHeadersPort();
    final chapter = Chapter(
      id: 'chapter-1',
      bookId: 'book-1',
      title: '第一章',
      index: 0,
      url: '',
    );
    final page = ReaderPage(
      book: Book(id: 'book-1', name: '测试书'),
      chapter: chapter,
      allChapters: [chapter],
      imageHeadersPort: imageHeadersPort,
    );

    expect(page.imageHeadersPort, same(imageHeadersPort));
  });

  test(
    'test hosts can explicitly inject the reader source presentation port',
    () {
      final sourcePresentationPort = _FakeReaderSourcePresentationPort();
      final chapter = Chapter(
        id: 'chapter-1',
        bookId: 'book-1',
        title: '第一章',
        index: 0,
        url: '',
      );
      final page = ReaderPage(
        book: Book(id: 'book-1', name: '测试书'),
        chapter: chapter,
        allChapters: [chapter],
        sourcePresentationPort: sourcePresentationPort,
      );

      expect(page.sourcePresentationPort, same(sourcePresentationPort));
    },
  );

  test('test hosts can explicitly inject the simulated reading port', () {
    final simulatedReadingPort = ReaderSimulatedReadingPortCallbacks(
      findBookById: (_) => null,
      updateSimulatedReading:
          (
            Book book, {
            required bool enabled,
            required String startDate,
            required int startChapter,
            required int dailyChapters,
          }) async => book,
    );
    final chapter = Chapter(
      id: 'chapter-1',
      bookId: 'book-1',
      title: '第一章',
      index: 0,
      url: '',
    );
    final page = ReaderPage(
      book: Book(id: 'book-1', name: '测试书'),
      chapter: chapter,
      allChapters: [chapter],
      simulatedReadingPort: simulatedReadingPort,
    );

    expect(page.simulatedReadingPort, same(simulatedReadingPort));
  });
}
