import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/book/book.dart';
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
}
