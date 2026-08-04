import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/reader/manga_chapter_content_port.dart';
import 'package:legado_flutter/application/reader/manga_chapter_list_port.dart';
import 'package:legado_flutter/application/reader/manga_progress_port.dart';
import 'package:legado_flutter/application/reader/manga_source_presentation_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/features/reader/manga_reader_page.dart';

import '../../helpers/fake_manga_prefs_port.dart';

void main() {
  test('test hosts can explicitly inject the manga preference fake', () {
    final prefs = FakeMangaPrefsPort();
    final page = MangaReaderPage(
      book: Book(id: 'book-1', name: '测试漫画'),
      chapters: const [],
      prefs: prefs,
    );

    expect(page.prefs, same(prefs));
  });

  test('test hosts can explicitly inject the manga content port', () {
    const contentPort = _FakeMangaChapterContentPort();
    final page = MangaReaderPage(
      book: const Book(id: 'book-1', name: '测试漫画'),
      chapters: const [],
      contentPort: contentPort,
    );

    expect(page.contentPort, same(contentPort));
  });

  test('test hosts can explicitly inject the manga progress port', () {
    const progressPort = _FakeMangaProgressPort();
    final page = MangaReaderPage(
      book: const Book(id: 'book-1', name: '测试漫画'),
      chapters: const [],
      progressPort: progressPort,
    );

    expect(page.progressPort, same(progressPort));
  });

  test('test hosts can explicitly inject the manga chapter list port', () {
    const chapterListPort = _FakeMangaChapterListPort();
    final page = MangaReaderPage(
      book: const Book(id: 'book-1', name: '测试漫画'),
      chapters: const [],
      chapterListPort: chapterListPort,
    );

    expect(page.chapterListPort, same(chapterListPort));
  });

  test(
    'test hosts can explicitly inject the manga source presentation port',
    () {
      const sourcePresentationPort = _FakeMangaSourcePresentationPort();
      final page = MangaReaderPage(
        book: const Book(id: 'book-1', name: '测试漫画'),
        chapters: const [],
        sourcePresentationPort: sourcePresentationPort,
      );

      expect(page.sourcePresentationPort, same(sourcePresentationPort));
    },
  );
}

final class _FakeMangaChapterContentPort implements MangaChapterContentPort {
  const _FakeMangaChapterContentPort();

  @override
  Future<String> loadChapterContent({
    required Book book,
    required Chapter chapter,
  }) async => '';
}

final class _FakeMangaProgressPort implements MangaProgressPort {
  const _FakeMangaProgressPort();

  @override
  Future<void> updateProgress(
    String bookId,
    double progress,
    String? chapter, {
    int pageIndex = 0,
    int? durChapterIndex,
  }) async {}
}

final class _FakeMangaChapterListPort implements MangaChapterListPort {
  const _FakeMangaChapterListPort();

  @override
  List<Chapter> get currentChapters => const [];
}

final class _FakeMangaSourcePresentationPort
    implements MangaSourcePresentationPort {
  const _FakeMangaSourcePresentationPort();

  @override
  String sourceNameForBook(Book book) => '测试书源';
}
