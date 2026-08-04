import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/infrastructure/reader/manga_chapter_list_port_adapter.dart';

void main() {
  test('returns an immutable current chapter snapshot', () {
    final chapter = const Chapter(
      id: 'chapter-1',
      bookId: 'book-1',
      title: '第一章',
      index: 0,
      url: 'chapter-1',
    );
    final adapter = MangaChapterListPortAdapter(chapters: () => [chapter]);

    final chapters = adapter.currentChapters;
    expect(chapters, [chapter]);
    expect(() => chapters.add(chapter), throwsUnsupportedError);
  });
}
