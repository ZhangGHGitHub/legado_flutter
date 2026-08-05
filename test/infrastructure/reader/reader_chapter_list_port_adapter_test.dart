import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/infrastructure/reader/reader_chapter_list_port_adapter.dart';

void main() {
  test('普通阅读器目录适配器返回不可变当前目录快照', () {
    const chapter = Chapter(
      id: 'chapter-1',
      bookId: 'book-1',
      title: '第一章',
      index: 0,
      url: 'chapter-1',
    );
    final adapter = ReaderChapterListPortAdapter(chapters: () => [chapter]);

    final chapters = adapter.currentChapters;

    expect(chapters, [chapter]);
    expect(() => chapters.add(chapter), throwsUnsupportedError);
  });
}
