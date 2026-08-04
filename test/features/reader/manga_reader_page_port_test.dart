import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/reader/manga_chapter_content_port.dart';
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
}

final class _FakeMangaChapterContentPort implements MangaChapterContentPort {
  const _FakeMangaChapterContentPort();

  @override
  Future<String> loadChapterContent({
    required Book book,
    required Chapter chapter,
  }) async => '';
}
